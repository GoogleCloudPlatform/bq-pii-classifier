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

variable "bigquery_dataset_name" {
  type = string
}

########################################################################################################################
#                                           BQ Stack-Specific Variables
########################################################################################################################

variable "dlp_bq_configurations_folders" {
  type = list(number)
  description = "List of GCP folder IDs to be scanned by DLP discovery service for BigQuery"
}

variable "datastore_database_name" {
  type    = string
  default = "(default)"
}

variable "bq_remote_func_get_policy_tags_name" {
  type = string
  default = "get_table_policy_tags"
}

variable "sa_bq_remote_func_get_policy_tags" {
  type = string
  default = "sa-func-get-policy-tags"
}

########################################################################################################################
#                                            GCS Stack-Specific Variables
########################################################################################################################

variable "org_id" {
  type = number
}

variable "dlp_gcs_configurations_folders" {
  type = list(number)
  description = "List of GCP folder IDs to be scanned by DLP discovery service for GCS"
}

variable "bq_remote_func_get_buckets_metadata" {
  type = string
  default = "get_buckets_metadata"
}

variable "sa_bq_remote_func_get_buckets_metadata" {
  type = string
  default = "sa-func-get-buckets-metadata"
}