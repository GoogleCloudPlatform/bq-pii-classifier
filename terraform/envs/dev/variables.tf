variable "terraform_service_account_email" {
  type = string
  description = "The service account email to be used by terraform to deploy to GCP"
}

variable "application_project" {
  type = string
  description = "GCP project to host the application internal resources (e.g. DLP, Cloud Run, Service Accounts, etc)"
}

variable "publishing_project" {
  type = string
  description = "GCP project to host external/shared resources such as DLP results and monitoring views"
}

variable "compute_region" {
  description = "GCP region to deploy compute resources (e.g. Cloud Run)"
  type = string
}