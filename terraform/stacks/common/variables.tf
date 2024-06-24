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
  description = "Supported GCP regions for DLP inspection and tagging. These are the regions to run DLP jobs in and deploy policy tags taxonomies."
  type = set(string)
}

variable "bigquery_dataset_name" {
  type = string
}

variable "auto_dlp_results_table_name" {
  type = string
}

variable "standard_dlp_results_table_name" {
  type = string
}

variable "sa_tagging_dispatcher" {
  type = string
}

variable "sa_tagging_dispatcher_tasks" {
  type = string
}

variable "sa_tagger" {
  type = string
}

variable "sa_tagger_tasks" {
  type = string
}

variable "tagger_role" {
  type = string
}

variable "log_sink_name" {
  type = string
}

variable "scheduler_name" {
  type = string
}

variable "dispatcher_service_name" {
  type = string
}

variable "tagger_service_name" {
  type = string
}

variable "dispatcher_pubsub_topic" {
  type = string
}

variable "dispatcher_pubsub_sub" {
  type = string
}

variable "tagger_pubsub_topic" {
  type = string
}

variable "tagger_pubsub_sub" {
  type = string
}

variable "dispatcher_service_image" {
  type = string
}

variable "tagger_service_image" {
  type = string
}


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
    info_type_category = string
    # (standard | custom)
    policy_tag = string
    classification = string
    labels = list(object({key = string, value = string}))
    inspection_template_number = number
    taxonomy_number = number
  }))
}


variable "domain_mapping" {
  type = list(object({
    project = string,
    domain = string,
    datasets = list(object({
      name = string,
      domain = string
    })) // leave empty if no dataset overrides is required for this project
  }))
  description = "Mapping between domains and GCP projects or BQ Datasets. Dataset-level mapping will overwrite project-level mapping for a given project."
}



variable "iam_mapping" {
  type = map(map(list(string)))
  description = "Dictionary of mappings between domains/classification and IAM members to grant required permissions to read sensitive BQ columns belonging to that domain/classification"
}


variable "dlp_service_account" {
  type = string
  description = "service account email for DLP to grant permissions to via Terraform"
}

variable "cloud_scheduler_account" {
  type = string
  description = "Service agent account for Cloud Scheduler. Format service-<project number>@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

variable "is_dry_run_tags" {
  type = string
}

variable "is_dry_run_labels" {
  type = string
}

variable "cron_expression" {
  type = string
}

variable "is_auto_dlp_mode" {
  type = bool
}

variable "data_catalog_taxonomy_activated_policy_types" {
  type = list(string)
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

# Tagger settings.
variable "tagger_service_timeout_seconds" {
  type = number
}

variable "tagger_subscription_ack_deadline_seconds" {
  type = number
}

variable "tagger_subscription_message_retention_duration" {
  type = string
}

variable "promote_mixed_info_types" {
  type = bool
}

variable "custom_info_types_dictionaries" {
  type = list(object({
    name = string
    likelihood = string
    dictionary =list(string)
  }))
}

variable "custom_info_types_regex" {
  type = list(object({
    name = string
    likelihood = string
    regex = string
  }))
}