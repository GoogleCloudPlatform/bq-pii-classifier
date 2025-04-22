# adding provider block in all modules for tflint
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.2.2/docs/rules/terraform_required_providers.md
terraform {
  required_version = ">= 1.3.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 6.18.1"
    }
  }

  backend "gcs" {}
}