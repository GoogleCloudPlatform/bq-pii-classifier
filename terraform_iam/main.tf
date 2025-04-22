
provider "google" {
  project                     = var.application_project
  impersonate_service_account = var.terraform_service_account_email
}

resource "google_service_account" "sa_tagger_gcs" {
  project      = var.application_project
  account_id   = var.sa_tagger_gcs_name
  display_name = "Data annotations service for GCS"
}

resource "google_service_account" "sa_tagger_bq" {
  project      = var.application_project
  account_id   = var.sa_tagger_bq_name
  display_name = "Data annotations service for BigQuery"
}