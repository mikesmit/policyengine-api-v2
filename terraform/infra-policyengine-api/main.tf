provider "google" {
  project = var.project_id
}

module "cloud_run_full_api" {
  source = "./modules/fastapi_cloudrun"

  name = "full-api"
  description = "Full api containing all routes"
  container_tag = var.full_container_tag
  test_account_email = "tester@${var.project_id}.iam.gserviceaccount.com"

  limits = {
    cpu    = var.is_prod ? 2 : null
    memory = var.is_prod ? "1024Mi" : null
  }

  project_id=var.project_id
  region=var.region
  is_prod=var.is_prod
  slack_notification_channel_name=var.slack_notification_channel_name
  commit_url = var.commit_url
}

module "cloud_run_simulation_api" {
  source = "./modules/fastapi_cloudrun"

  name = "api-simulation"
  description = "PolicyEngine Simulation API"
  container_tag = var.simulation_container_tag
  test_account_email = "tester@${var.project_id}.iam.gserviceaccount.com"

  limits = {
    cpu    = 1
    memory = "4Gi"
  }

  project_id=var.project_id
  region=var.region
  is_prod=var.is_prod
  slack_notification_channel_name=var.slack_notification_channel_name
  commit_url = var.commit_url
}

# Create a workflow
resource "google_workflows_workflow" "simulation_workflow" {
  depends_on = [ google_service_account.workflow_sa ]
  name            = "simulation-workflow"
  region          = var.region
  description     = "Simulation workflow"
  service_account = google_service_account.workflow_sa.id

  deletion_protection = false # set to "true" in production

  labels = {
    env = var.is_prod ? "prod" : "test"
  }
  user_env_vars = {
    service_url = "${module.cloud_run_simulation_api.uri}/simulate/economy/comparison"
  }
  source_contents = file("../../projects/policyengine-api-simulation/workflow.yaml")
}

# Create a dedicated service account for workflow
resource "google_service_account" "workflow_sa" {
  account_id   = "simulation-workflows-sa"
  display_name = "Simulation Workflows Service Account"
}


