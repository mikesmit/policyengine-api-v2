locals {
  full_api_image = "${var.region}-docker.pkg.dev/${ var.project_id }/api-v2/policyengine-api-full:${var.full_container_tag}"
  simulation_api_image = "${var.region}-docker.pkg.dev/${ var.project_id }/api-v2/policyengine-api-simulation:${var.simulation_container_tag}"
}

provider "google" {
  project = var.project_id
}

# Create a custom service account
resource "google_service_account" "cloudrun_full_api" {
  account_id   = "full-api"
  display_name = "Cloud Run Service Account for Full API"
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
    containers {
      image = local.simulation_api_image
      resources {
        limits = {
          # Need to tune. This process currently eats memory
          cpu    = 1
          memory =  "4Gi"
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
      "serviceAccount:simulation-workflows-sa@${var.project_id}.iam.gserviceaccount.com",
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
  service_account = "serviceAccount:simulation-workflows-sa@${var.project_id}.iam.gserviceaccount.com"

  deletion_protection = false # set to "true" in production

  labels = {
    env = var.is_prod ? "prod" : "test"
  }
  user_env_vars = {
    service_url = "${google_cloud_run_v2_service.cloud_run_simulation_api.uri}/simulate/economy/comparison"
  }
  source_contents = file("../../projects/policyengine-api-simulation/workflow.yaml")
}
