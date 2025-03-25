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
  description = "The container image tag for the full API"
  type        = string
}

variable "simulation_container_tag" {
  description = "The container image tag for the simulation API"
  type        = string
}

variable "is_prod" {
  description = "Whether this is a production deployment"
  type        = bool
  default     = false
}

variable "hugging_face_token" {
  description = "The Hugging Face API token for the simulation API"
  type        = string
  sensitive   = true
}

variable "slack_notification_channel_name" {
  description = "Manually configured slack notification channel's name"
  type = string
  default = ""
}

variable "commit_url" {
  type = string
  description = "URL of the commit this deployment is associated with"
}
