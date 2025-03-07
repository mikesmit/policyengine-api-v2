output "full_api_url" {
  value = google_cloud_run_v2_service.cloud_run_full_api.uri
}

output "simulation_api_url" {
  value = google_cloud_run_v2_service.cloud_run_simulation_api.uri
}

output "workflow_id" {
  value = google_workflows_workflow.simulation_workflow.id
}
