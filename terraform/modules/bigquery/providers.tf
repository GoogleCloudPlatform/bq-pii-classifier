# adding provider block in all modules for tflint
# https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.2.2/docs/rules/terraform_required_providers.md
terraform {
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
}