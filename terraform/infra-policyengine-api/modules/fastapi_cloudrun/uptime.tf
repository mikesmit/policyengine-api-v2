
resource "google_monitoring_uptime_check_config" "cloudrun_health_check" {
  display_name = "${var.name} Health Check"
  # response time can be slower because of container spin up in beta.
  timeout      = var.is_prod ? "1s" : "10s"
  # don't waste resources waking up the beta container all the time. Just do it once a day.
  period       = var.is_prod ? "300s" : "86400s"

  http_check {
    path         = "/ping/alive"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
    service_agent_authentication {
      type = "OIDC_TOKEN"
      
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       =  regex("://([^/:]+)", google_cloud_run_v2_service.api.uri)[0]
    }
  }
}