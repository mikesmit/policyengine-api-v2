variable "project_id" {
  description = "The GCP project to deploy to"
  type        = string
}

variable "region" {
  description = "The region to deploy the cloud run service to."
  type        = string
  default     = "us-central1"
}

variable "full_container_tag" {
  description = "The container image tag for the full API. If not specified, defaults to 'desktop'"
  type        = string
  default     = "desktop"
}

variable "simulation_container_tag" {
  description = "The container image tag for the simulation API. If not specified, defaults to 'desktop'"
  type        = string
  default     = "desktop"
}

variable "is_prod" {
  description = "Whether this is a production deployment"
  type        = bool
  default     = false
}