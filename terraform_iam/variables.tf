variable "terraform_service_account_email" {
  type        = string
  description = "The service account email to be used by terraform to deploy to GCP"
}

variable "application_project" {
  type = string
}

variable "sa_tagger_gcs_name" {
  type = string
  default = "tagger-gcs"
}

variable "sa_tagger_bq_name" {
  type = string
  default = "tagger-bq"
}