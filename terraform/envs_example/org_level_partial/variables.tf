#
#
#  Copyright 2025 Google LLC
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       https://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#  implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#

variable "terraform_service_account_email" {
  type        = string
  description = "Serviced account to be used by Terraform to deploy resources"
}

variable "org_id" {
  type        = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
}

variable "application_project" {
  type        = string
  description = "GCP project to host the application internal resources (e.g. DLP, Cloud Run, Service Accounts, etc)"
}

variable "publishing_project" {
  type        = string
  description = "GCP project to host external/shared resources such as DLP results and monitoring views"
}

variable "compute_region" {
  description = "GCP region to deploy compute resources (e.g. Cloud Run)"
  type        = string
}

variable "data_region" {
  description = "GCP region to store application data (e.g. DLP results, logs, etc)"
  type        = string
}

variable "terraform_data_deletion_protection" {
  type        = bool
  description = "When set to `True`, Terraform will not delete data assets like buckets and BQ datasets"
}

variable "source_data_regions" {
  description = "Supported GCP regions for DLP inspection and tagging. These are the regions to run DLP jobs in and deploy policy tags taxonomies."
  type        = set(string)
}

variable "deploy_dlp_inspection_template_to_global_region" {
  type        = bool
  description = "When set to `True`, DLP inspection template will be deployed to the 'global' region in addition to regions set in source data regions. This allows DLP to scan resources in any region."
}
