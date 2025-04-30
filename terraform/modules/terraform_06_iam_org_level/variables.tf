variable "terraform_service_account_email" {
  type        = string
  description = "The service account email to be used by terraform to deploy to GCP"
}

variable "application_project" {
  type = string
  description = "GCP project name to deploy application components to"
}

variable "org_id" {
  type = number
}