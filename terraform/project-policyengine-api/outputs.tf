output "project_bucket" {
    value = local.project_bucket
    description = "bucket for storing project terraform state"
}

output "stage" {
    value = var.stage
    description = "stage configured for this project"
}

output "project_id" {
    value = module.project.project_id
    description = "ID of this project"
}

output "project_base_id" {
    value = var.project_id
    description = "Base project ID (can be used to create resource names)"
}

output "service_account_email" {
    value = module.project.service_account_email
    description = "Project service account"
}

output "docker_repository_namespace" {
    value = "${google_artifact_registry_repository.docker_repo.location}-docker.pkg.dev/${module.project.project_id}/${google_artifact_registry_repository.docker_repo.name}"
}

output "build_account_email" {
    value = google_service_account.build.email
}
