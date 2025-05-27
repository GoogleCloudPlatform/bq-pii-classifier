# adding provider block in all modules for tflint
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.2.2/docs/rules/terraform_required_providers.md
terraform {
  required_version = ">= 1.12.1"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "= 5.20.0"
    }

    google-beta = {
      source = "hashicorp/google"
      version = "= 5.20.0"
    }
  }

  # DONT REMOVE
  provider_meta "google" {
    module_name = "cloud-solutions/bq-pii-classifier–deploy-v2.0"
  }

  backend "gcs" {}
}
