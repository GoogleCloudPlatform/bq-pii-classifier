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

variable "project" {
  type = string
}

variable "compute_region" {
  type = string
}

variable "data_region" {
  type = string
}

variable "source_data_regions" {
  type = list(string)
}

variable "sa_inspection_dispatcher" {
  type = string
}

variable "sa_inspection_dispatcher_tasks" {
  type = string
}

variable "sa_inspector" {
  type = string
}

variable "sa_inspector_tasks" {
  type = string
}

variable "scheduler_name" {
  type = string
}

variable "dispatcher_service_name" {
  type = string
}

variable "inspector_service_name" {
  type = string
}

variable "dispatcher_pubsub_topic" {
  type = string
}

variable "dispatcher_pubsub_sub" {
  type = string
}

variable "inspector_pubsub_topic" {
  type = string
}

variable "inspector_pubsub_sub" {
  type = string
}

variable "dispatcher_service_image" {
  type = string
}
variable "inspector_service_image" {
  type = string
}

# BQ scanning scope
# Optional fields. At least one should be provided among the _INCLUDE configs
# format: project.dataset.table1, project.dataset.table2, etc
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
  type = string
  description = "Service agent account for Cloud Scheduler. Format service-<project number>@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

variable "bigquery_dataset_name" {
  type = string
}

variable "standard_dlp_results_table_name" {
  type = string
}

variable "dlp_inspection_templates_ids" {
  description = "A list of objects, each representing a deployment of inspection templates per region"
  type = list(object({
    ids = list(string)
    region = string
  }))
}

variable "cron_expression" {
  type = string
  description = "Cron expression used by the Cloud Scheduler to run a full scan"
}

variable "table_scan_limits_json_config" {
  type = string
  description = "JSON config to specify table scan limits intervals"
}

variable "tagger_topic_id" {
  type = string
}

variable "dlp_min_likelihood" {
  type = string
}

variable "dlp_max_findings_per_item" {
  type = number
}

//How to sample rows if not all rows are scanned. Meaningful only when used in conjunction with either rows_limit or rows_limit_percent. If not specified, rows are scanned in the order BigQuery reads them.
//
//RANDOM_START = 2
//SAMPLE_METHOD_UNSPECIFIED = 0
//TOP = 1
variable "dlp_sampling_method" {
  type = number
}

variable "gcs_flags_bucket_name" {
  type = string
}

# Dispatcher settings.
variable "dispatcher_service_timeout_seconds" {
  type = number
}

variable "dispatcher_subscription_ack_deadline_seconds" {
  type = number
}

variable "dispatcher_subscription_message_retention_duration" {
  type = string
}

# Inspector settings.
variable "inspector_service_timeout_seconds" {
  type = number
}

variable "inspector_subscription_ack_deadline_seconds" {
  type = number
}

variable "inspector_subscription_message_retention_duration" {
  type = string
}

variable "default_labels" {
  type = map(string)
}




