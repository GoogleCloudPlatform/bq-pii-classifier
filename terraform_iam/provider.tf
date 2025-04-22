terraform {
  required_version = ">= 1.3.3"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "= 6.18.1"
    }
  }
}