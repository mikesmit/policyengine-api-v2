locals {
  api_image = "${var.region}-docker.pkg.dev/${ var.project_id }/api-v2/policyengine-api-full:${var.container_tag}"
}

# Create a custom service account
resource "google_service_account" "api" {
  account_id   = "${var.name}"
  display_name = "Cloud Run Service Account for ${var.name} api"
}

resource "google_project_iam_member" "api_roles" {
  for_each = toset(["roles/monitoring.metricWriter", "roles/logging.logWriter", "roles/cloudtrace.agent"])
  project = var.project_id
  role = each.key
  member = "serviceAccount:${google_service_account.api.email}"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service
resource "google_cloud_run_v2_service" "api" {
  provider = google-beta
  project = var.project_id
  name     = var.name
  location = var.region
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_ALL"

  description = var.description

  template {
    service_account = google_service_account.api.email
    # Assumption from cost estimate.
    max_instance_request_concurrency = var.is_prod ? 80 : null
    containers {
      image = local.api_image
      resources {
        #default to whatever the cheapest instance is unless in prod in which
        # case values are again based on the cost esitmate.
        limits = {
          cpu    = var.limits.cpu
          memory = var.limits.memory
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

data "google_project" "project" {
  project_id = var.project_id
}

data "google_iam_policy" "api" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${var.test_account_email}",
      "serviceAccount:service-${data.google_project.project.number}@gcp-sa-monitoring-notification.iam.gserviceaccount.com"
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "api" {
  location = google_cloud_run_v2_service.api.location
  project  = google_cloud_run_v2_service.api.project
  service  = google_cloud_run_v2_service.api.name

  policy_data = data.google_iam_policy.api.policy_data
}