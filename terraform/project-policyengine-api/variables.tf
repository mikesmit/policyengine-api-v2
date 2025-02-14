variable org_id {
    type = string
}

variable stage {
    type = string
    description = "Added to resource names so it's always clear what stage you are looking at in console/logs/etc."
}

variable project_id {
    type = string
    default = "policyengine-api"
    description = "The base project id you want to use. This will be added to stage and a unique ID."
}

variable billing_account {
    type = string
}

variable is_prod {
    type = bool
    default = false
    description = "prod deployments will use more expensive services and scaling to support production use cases"
}

variable region {
    type=string
    description = "region to put things in"
    default = "us-central1"
}