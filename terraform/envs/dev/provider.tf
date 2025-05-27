terraform {
  required_version = ">= 1.3.3"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "= 6.18.1"
    }
  }

  provider_meta "google" {
    module_name = "cloud-solutions/gcp-pii-classifier–deploy-v1.0"
  }
}

provider "google" {
  project                     = var.application_project
  region                      = var.compute_region
  impersonate_service_account = var.terraform_service_account_email
}