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

variable "env" {}

variable "bigquery_dataset_name" {
}

variable "auto_dlp_results_table_name" {
}

variable "standard_dlp_results_table_name" {
}

variable "sa_inspection_dispatcher" {
}

variable "sa_tagging_dispatcher" {
}

variable "sa_tagging_dispatcher_tasks" {
}

variable "sa_inspection_dispatcher_tasks" {
}

variable "sa_inspector" {}
variable "sa_inspector_tasks" {}
variable "sa_listener" {}
variable "sa_listener_tasks" {}

variable "sa_tagger" {
}

variable "sa_tagger_tasks" {
}

variable "tagger_role" {
}

variable "log_sink_name" {
}

variable "scheduler_name" {
}

variable "dispatcher_service_name" {
}

variable "tagger_service_name" {
}

variable "dispatcher_pubsub_topic" {
}

variable "dispatcher_pubsub_sub" {
}

variable "tagger_pubsub_topic" {
}

variable "tagger_pubsub_sub" {
}

variable "dispatcher_service_image" {}

variable "tagger_service_image" {}


# DLP scanning scope
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

variable "classification_taxonomy" {
  type = list(object({
    info_type = string
    info_type_category = string # (standard | custom)
    policy_tag = string
    classification = string
  }))
}


variable "domain_mapping" {
  description = "Mapping between domains and GCP projects or BQ Datasets. Dataset-level mapping will overwrite project-level mapping for a given project."
}



variable "iam_mapping" {
  description = "Dictionary of mappings between domains/classification and IAM members to grant required permissions to read sensitive BQ columns belonging to that domain/classification"
}


variable "dlp_service_account" {
  description = "service account email for DLP to grant permissions to via Terraform"
}

variable "cloud_scheduler_account" {
  description = "Service agent account for Cloud Scheduler. Format service-<project number>@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

variable "is_dry_run" {

}

variable "cron_expression" {

}

variable "dlp_findings_view_template_name" {}

variable "is_auto_dlp_mode" {}






