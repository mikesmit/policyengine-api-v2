variable "is_prod" {
  description = "Whether this is a production deployment"
  type        = bool
}

variable "project_id" {
  description = "The GCP project to deploy to"
  type        = string
}

variable "region" {
  description = "The region to deploy the cloud run service to."
  type        = string
}

variable "container_tag" {
  description = "The container image tag to deploy."
  type        = string
}

variable limits {
  type = object({
    cpu    = number
    memory = string
  })
}

variable "description" {
  type = string
}

variable "name" {
  type = string
}

variable "slack_notification_channel_name" {
  type = string
  default = ""
}

variable "test_account_email" {
  type = string
}

variable "commit_url" {
  type = string
  description = "URL of the commit this deployment is associated with"
}
