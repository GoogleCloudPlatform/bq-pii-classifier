variable "terraform_service_account_email" {
  type        = string
  description = "The service account email to be used by terraform to deploy to GCP"
}

variable "application_project" {
  type = string
  description = "GCP project name to deploy application components to"
}


variable "application_service_account_name" {
  type = string
  default = "annotations-app"
  description = "Name of the service account to run the application components"
}

variable "tagger_gcs_service_account_name" {
  type = string
  default = "annotations-gcs"
  description = "Name of the service account to run the GCS annotations service"
}

variable "tagger_bq_service_account_name" {
  type = string
  default = "annotations-bq"
  description = "Name of the service account to run the BigQuery annotations service"
}