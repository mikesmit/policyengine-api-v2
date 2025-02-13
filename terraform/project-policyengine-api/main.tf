locals {
  base_project_id = "${var.stage}-${var.project_id}"
}

provider "google" {
  region = var.region
}

provider "google-beta" {
  region = var.region
}

module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                 = local.base_project_id
  random_project_id    = true
  org_id               = var.org_id
  #bucket_name          = "${var.stage}-terraform-state"
  bucket_force_destroy = var.is_prod ? false : true
  billing_account      = var.billing_account
  project_sa_name      = "project" # email will include the project name which in turn has stage
  bucket_project       = local.base_project_id

  default_service_account = "deprivilege"
  deletion_policy = var.is_prod ? "PREVENT" : "DELETE"
  

  # revisit cloud armor, budget alarm, etc.
  

  activate_apis = [
    # requirements to build and deploy a cloudrun container
    # https://cloud.google.com/build/docs/build-push-docker-image
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "compute.googleapis.com", 
    "run.googleapis.com"]
}


#Look up the default compute account so we can add back in permissions.
data "google_service_account" "default_compute" {
  account_id = "${module.project.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [ module.project]
}

#Give the detault compute account the roles required to build and store artifacts.
resource "google_project_iam_member" "compute-service-account-roles" {
  for_each = toset(["roles/artifactregistry.writer", "roles/storage.objectUser"])
  project = module.project.project_id
  role = each.key
  member = "serviceAccount:${data.google_service_account.default_compute.email}"
}


//service account for building stuff
resource "google_service_account" "build" {
  project = module.project.project_id
  account_id = "builder" #email will contain the  project id which has stage.
  description = "service account for starting artifact builds."
}

//Needs to be able to submit builds.
resource "google_project_iam_member" "build-service-account-roles" {
  for_each = toset(["roles/cloudbuild.builds.builder"])
  project = module.project.project_id
  role = each.key
  member = "serviceAccount:${google_service_account.build.email}"
}

//and also in turn, needs to be able to use the compute service account.
resource "google_service_account_iam_binding" "compute-service-iam" {
  service_account_id = data.google_service_account.default_compute.id
  role               = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${google_service_account.build.email}"
  ]
}

# Repository for storing docker artifacts, etc.
resource "google_artifact_registry_repository" "docker_repo" {
    repository_id = "api-v2"
    description = "Docker repo for images created under the ${module.project.project_name} project"
    format = "DOCKER"
    project = module.project.project_id
}

locals {
  //for some reason they don't export the bucket, just the url. And that as an array.
  //pull the one and only one bucket url and get the bucket name
  project_bucket = trimprefix(module.project.project_bucket_url[0], "gs://")
}

//this will bottstrap our backend.tf to use the state bucket after we've 
//created the project.
//https://cloud.google.com/docs/terraform/resource-management/store-state
resource "local_file" "default" {
  file_permission = "0644"
  filename        = "${path.cwd}/backend.tf"
  content = <<-EOT
  terraform {
    backend "gcs" {
      bucket = "${local.project_bucket}"
      prefix = "terraform/project"
    }
  }
  EOT
}