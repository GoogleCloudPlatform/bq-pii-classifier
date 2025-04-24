variable "terraform_service_account_email" {
  type        = string
  description = "The service account email to be used by terraform to deploy to GCP"
}

variable "application_project" {
  type = string
  description = "GCP project name to deploy application components to"
}

variable "publishing_project" {
  type = string
  description = "GCP project to host external/shared resources such as DLP results and monitoring views"
}


variable "application_service_account_name" {
  type = string
  default = "annotations-app"
  description = "Name of the service account to run the application components"
}