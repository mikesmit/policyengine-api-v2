locals {
  full_api_image = "${var.region}-docker.pkg.dev/${ var.project_id }/api-v2/policyengine-api-full:${var.full_container_tag}"
  simulation_api_image = "${var.region}-docker.pkg.dev/${ var.project_id }/api-v2/policyengine-api-simulation:${var.simulation_container_tag}"
}

provider "google" {
  project = var.project_id
}

# Enable required APIs
resource "google_project_service" "secretmanager_api" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Create a custom service account
resource "google_service_account" "cloudrun_full_api" {
  account_id   = "full-api"
  display_name = "Cloud Run Service Account for Full API"
}

# Create a dedicated service account for workflow
resource "google_service_account" "workflow_sa" {
  account_id   = "simulation-workflows-sa"
  display_name = "Simulation Workflows Service Account"
}

resource "google_project_iam_member" "deploy_service_account_roles" {
  for_each = toset(["roles/monitoring.metricWriter", "roles/logging.logWriter", "roles/cloudtrace.agent"])
  project = var.project_id
  role = each.key
  member = "serviceAccount:${google_service_account.cloudrun_full_api.email}"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service
resource "google_cloud_run_v2_service" "cloud_run_full_api" {
  provider = google-beta
  project = var.project_id
  name     = "api-full"
  location = var.region
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_ALL"

  description = "PolicyEngine Full API"

  template {
    service_account = google_service_account.cloudrun_full_api.email
    # Assumption from cost estimate.
    max_instance_request_concurrency = var.is_prod ? 80 : null
    containers {
      image = local.full_api_image
      resources {
        #default to whatever the cheapest instance is unless in prod in which
        # case values are again based on the cost esitmate.
        limits = {
          cpu    = var.is_prod ? 2 : null
          memory = var.is_prod ? "1024Mi" : null
        }
      }
      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds = 1
        period_seconds = 5
        failure_threshold = 4
        http_get {
          path = "/ping/started"
        }
      }
      # Only include liveness_probe in production environment so we don't
      # waste money running beta containers.
      dynamic "liveness_probe" {
        for_each = var.is_prod ? [1] : []
        content {
          period_seconds = 30 
          timeout_seconds = 1 
          failure_threshold = 2
          http_get {
            path = "/ping/alive"
          }
        }
      }
    }
    scaling {
      # always keep one instance hot in prod
      min_instance_count = var.is_prod ? 1 : 0
      # in beta don't create a bunch of containers
      # max in prod based on assumptions from cost estimate
      max_instance_count = var.is_prod ? 10 : 1
    }
  }
}

data "google_iam_policy" "full_api" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:tester@${var.project_id}.iam.gserviceaccount.com",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "full_api" {
  location = google_cloud_run_v2_service.cloud_run_full_api.location
  project  = google_cloud_run_v2_service.cloud_run_full_api.project
  service  = google_cloud_run_v2_service.cloud_run_full_api.name

  policy_data = data.google_iam_policy.full_api.policy_data
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service
resource "google_cloud_run_v2_service" "cloud_run_simulation_api" {
  provider = google-beta
  project = var.project_id
  name     = "api-simulation"
  location = var.region
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_ALL"

  description = "PolicyEngine Simulation API"

  template {
    service_account = google_service_account.workflow_sa.email
    containers {
      image = local.simulation_api_image
      resources {
        limits = {
          # Need to tune. This process currently eats memory
          cpu    = 4
          memory =  "16Gi"
        }
      }
      env {
        name  = "HUGGING_FACE_TOKEN"
        value_source {
          secret_key_ref {
            secret = google_secret_manager_secret.hugging_face_token.secret_id
            version = "latest"
          }
        }
      }
    }
    scaling {
      min_instance_count = var.is_prod ? 1 : 0
      max_instance_count = var.is_prod ? 10 : 1
    }
  }
}

# Workflow and tester can both invoke the cloudrun service
data "google_iam_policy" "simulation_api" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:tester@${var.project_id}.iam.gserviceaccount.com",
      "serviceAccount:${google_service_account.workflow_sa.email}",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "simulation_api" {
  location = google_cloud_run_v2_service.cloud_run_simulation_api.location
  project  = google_cloud_run_v2_service.cloud_run_simulation_api.project
  service  = google_cloud_run_v2_service.cloud_run_simulation_api.name

  policy_data = data.google_iam_policy.simulation_api.policy_data
}

# Create a workflow
resource "google_workflows_workflow" "simulation_workflow" {
  name            = "simulation-workflow"
  region          = var.region
  description     = "Simulation workflow"
  service_account = google_service_account.workflow_sa.email

  deletion_protection = false # set to "true" in production

  labels = {
    env = var.is_prod ? "prod" : "test"
  }
  user_env_vars = {
    service_url = "${google_cloud_run_v2_service.cloud_run_simulation_api.uri}/simulate/economy/comparison"
  }
  source_contents = file("../../projects/policyengine-api-simulation/workflow.yaml")
}

# Grant necessary permissions to the workflow service account
resource "google_project_iam_member" "workflow_sa_permissions" {
  for_each = toset(["roles/workflows.invoker", "roles/run.invoker", "roles/secretmanager.secretAccessor"])
  project = var.project_id
  role = each.key
  member = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# Create a secret for the Hugging Face token
resource "google_secret_manager_secret" "hugging_face_token" {
  secret_id = "hugging-face-token"
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.secretmanager_api]
}

# Add the secret version with the token value
resource "google_secret_manager_secret_version" "hugging_face_token" {
  secret = google_secret_manager_secret.hugging_face_token.id
  secret_data = var.hugging_face_token
}
