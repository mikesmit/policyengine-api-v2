output "full_api_url" {
  value = module.cloud_run_full_api.service_uri
}

output "simulation_api_url" {
  value = module.cloud_run_simulation_api.service_uri
}

output "workflow_id" {
  value = google_workflows_workflow.simulation_workflow.id
}