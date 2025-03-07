locals {
    # Assumption from cost estimate. May need to tweak based on real performance.
    max_instance_request_concurrency = var.is_prod ? 80 : null
    # API is reachable if production otherwise internal-only.
    members = var.is_prod ? ["allUsers"] : []
    # keep one instance running at all times in production for responsiveness.
    # in other environments don't waste the money
    min_instance_count = var.is_prod ? 1 : 0
    max_instance_count = var.is_prod ? 10 : 1
    
    # minimum instance specs only apply in production
    cpu_limit = var.is_prod ? "2" : null
    memory_limit = var.is_prod ? "1024Mi" : null

    full_api_image = "${var.region}-docker.pkg.dev/${ var.project_id }/api-v2/policyengine-api-full:${var.full_container_tag}"
    simulation_api_image = "${var.region}-docker.pkg.dev/${ var.project_id }/api-v2/policyengine-api-simulation:${var.simulation_container_tag}"
}

provider "google" {
  project = var.project_id
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service
resource "google_cloud_run_v2_service" "cloud_run_full_api" {
  provider = google-beta
  project = var.project_id
  name     = "api-full"
  location = "us-central1"
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_ALL"

  description = "PolicyEngine Full API"

  template {
    containers {
      image = local.full_api_image
      resources {
        limits = {
          cpu    = local.cpu_limit
          memory = local.memory_limit
        }
      }
    }
    scaling {
      min_instance_count = local.min_instance_count
      max_instance_count = local.max_instance_count
    }
  }
}

data "google_iam_policy" "private" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:tester@${var.project_id}.iam.gserviceaccount.com",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "full_api_test_access" {
  location = google_cloud_run_v2_service.cloud_run_full_api.location
  project  = google_cloud_run_v2_service.cloud_run_full_api.project
  service  = google_cloud_run_v2_service.cloud_run_full_api.name

  policy_data = data.google_iam_policy.private.policy_data
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service
resource "google_cloud_run_v2_service" "cloud_run_simulation_api" {
  provider = google-beta
  project = var.project_id
  name     = "api-simulation"
  location = "us-central1"
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_ALL"

  description = "PolicyEngine Simulation API"

  template {
    containers {
      image = local.simulation_api_image
      resources {
        limits = {
          cpu    = 1
          memory =  "4Gi"
        }
      }
    }
    scaling {
      min_instance_count = local.min_instance_count
      max_instance_count = local.max_instance_count
    }
  }
}

resource "google_cloud_run_service_iam_policy" "simulation_api_test_access" {
  location = google_cloud_run_v2_service.cloud_run_simulation_api.location
  project  = google_cloud_run_v2_service.cloud_run_simulation_api.project
  service  = google_cloud_run_v2_service.cloud_run_simulation_api.name

  policy_data = data.google_iam_policy.private.policy_data
}

# Create a workflow
resource "google_workflows_workflow" "simulation_workflow" {
  name            = "simulation-workflow"
  region          = var.region
  description     = "Simulation workflow"
  service_account = google_service_account.workflow_sa.id

  deletion_protection = false # set to "true" in production

  labels = {
    env = var.is_prod ? "prod" : "test"
  }
  user_env_vars = {
    service_url = "${google_cloud_run_v2_service.cloud_run_simulation_api.uri}/simulate"
  }
  source_contents = file("../../projects/policyengine-api-simulation/workflow.yaml")

  depends_on = [google_project_service.workflows_api]
}

# Create a dedicated service account for workflow
resource "google_service_account" "workflow_sa" {
  account_id   = "simulation-workflows-sa"
  display_name = "Simulation Workflows Service Account"
}

# Enable Workflows API
resource "google_project_service" "workflows_api" {
  service            = "workflows.googleapis.com"
  disable_on_destroy = false
}
