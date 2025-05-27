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

    archive = {
      source = "hashicorp/archive"
      version = "2.7.0"
    }

    random = {
      source = "hashicorp/random"
      version = "3.6.2"
    }
  }
}