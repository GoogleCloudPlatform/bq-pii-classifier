variable "terraform_service_account_email" {
  type = string
  description = "Serviced account to be used by Terraform to deploy resources"
}

variable "org_id" {
  type = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
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

variable "data_region" {
  description = "GCP region to store application data (e.g. DLP results, logs, etc)"
  type = string
}

variable "terraform_data_deletion_protection" {
  type = bool
  description = "When set to `True`, Terraform will not delete data assets like buckets and BQ datasets"
}

variable "source_data_regions" {
  description = "Supported GCP regions for DLP inspection and tagging. These are the regions to run DLP jobs in and deploy policy tags taxonomies."
  type = set(string)
}

variable "services_container_image_name" {
  type = string
  description = "Existing Container image name that contains the services used by Cloud Run and published in the host project. Example: annotations-services:latest"
}


