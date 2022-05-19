#   Copyright 2021 Google LLC
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

variable "project" {}

variable "compute_region" {}

variable "data_region" {}

variable "sa_inspection_dispatcher" {
}

variable "sa_inspection_dispatcher_tasks" {
}

variable "sa_inspector" {
}

variable "sa_inspector_tasks" {
}

variable "sa_listener" {
}

variable "sa_listener_tasks" {
}

variable "scheduler_name" {
}

variable "dispatcher_service_name" {
}

variable "inspector_service_name" {
}

variable "listener_service_name" {
}

variable "dispatcher_pubsub_topic" {
}

variable "dispatcher_pubsub_sub" {
}

variable "inspector_pubsub_topic" {
}

variable "inspector_pubsub_sub" {
}

variable "listener_pubsub_topic" {
}

variable "listener_pubsub_sub" {
}

variable "dispatcher_service_image" {}
variable "inspector_service_image" {}
variable "listener_service_image" {}


# BQ scanning scope
# Optional fields. At least one should be provided among the _INCLUDE configs
# format: project.dataset.table1, project.dataset.table2, etc
variable "tables_include_list" {
  type = list(string)
}
variable "datasets_include_list" {
  type = list(string)
}
variable "projects_include_list" {
  type = list(string)
}
variable "datasets_exclude_list" {
  type = list(string)
}
variable "tables_exclude_list" {
  type = list(string)
}

variable "cloud_scheduler_account" {
  description = "Service agent account for Cloud Scheduler. Format service-<project number>@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

variable "dlp_service_account" {
  description = "service account email for DLP to grant permissions to via Terraform"
}

variable "bigquery_dataset_name" {
}

variable "standard_dlp_results_table_name" {
}



variable "dlp_inspection_template_id" {}

variable "cron_expression" {
  type = string
  description = "Cron expression used by the Cloud Scheduler to run a full scan"
}

variable "table_scan_limits_json_config" {
  type = string
  description = "JSON config to specify table scan limits intervals"
}

variable "tagger_topic_id" {}

variable "dlp_min_likelihood" {}

variable "dlp_max_findings_per_item" {}

//How to sample rows if not all rows are scanned. Meaningful only when used in conjunction with either rows_limit or rows_limit_percent. If not specified, rows are scanned in the order BigQuery reads them.
//
//RANDOM_START = 2
//SAMPLE_METHOD_UNSPECIFIED = 0
//TOP = 1
variable "dlp_sampling_method" {}

variable "gcs_flags_bucket_name" {}

# Dispatcher settings.
variable "dispatcher_service_timeout_seconds" {}

variable "dispatcher_subscription_ack_deadline_seconds" {}

variable "dispatcher_subscription_message_retention_duration" {}

# Inspector settings.
variable "inspector_service_timeout_seconds" {}

variable "inspector_subscription_ack_deadline_seconds" {}

variable "inspector_subscription_message_retention_duration" {}

# Listener settings.
variable "listener_service_timeout_seconds" {}

variable "listener_subscription_ack_deadline_seconds" {}

variable "listener_subscription_message_retention_duration" {}




