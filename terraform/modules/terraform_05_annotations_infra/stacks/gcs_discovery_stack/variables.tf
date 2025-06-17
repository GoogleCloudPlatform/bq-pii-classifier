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

## REQUIRED VARIABLES

### Variables passed from main

variable "project" {
  type = string
}

variable "compute_region" {
  type = string
}

variable "gar_docker_repo_name" {
  type = string
}

variable "dlp_dataset_name" {
  type = string
}

variable "logging_dataset_name" {
  type = string
}

variable "tagger_service_timeout_seconds" {
  type = number
}

variable "tagger_subscription_ack_deadline_seconds" {
  type = number
}

variable "tagger_subscription_message_retention_duration" {
  type = string
}

variable "is_dry_run_labels" {
  type = bool
}

variable "info_type_map" {
  // map( info_type_name: str, info_type_meta_data: object) where info_type_meta_data is an object( classification:str, labels: list) and labels is a list of key-value pairs represented as a map
  type = map(object({ classification = string, labels = list(map(string)) }))
}

### Stack specific variables - required by user

variable "image_name" {
  type = string
}

## ### Stack specific variables - Default value variables from main

variable "dlp_gcs_bq_results_table_name" {
  type        = string
  description = "Name of the table that DLP will create to save the findings. This will be created in the solution dataset"
}

##### GCS Tagger Service ######

variable "tagger_gcs_service_name" {
  type = string
}

variable "tagger_gcs_pubsub_topic" {
  type = string
}

variable "tagger_gcs_pubsub_sub" {
  type = string
}

variable "gcs_existing_labels_regex" {
  type = string
}

variable "workflows_gcs_name" {
  type = string
}

variable "workflows_gcs_description" {
  type = string
}

variable "logging_table_name" {
  type = string
}

variable "bq_view_run_summary" {
  type = string
}

variable "terraform_data_deletion_protection" {
  type = bool
}

variable "info_type_map_file_path" {
  type = string
}

variable "publishing_project" {
  type = string
}

variable "dispatcher_cloud_batch_memory_mib" {
  type = number
}

variable "dispatcher_cloud_batch_cpu_millis" {
  type = number
}

variable "dispatcher_cloud_batch_max_run_duration_seconds" {
  type = number
}

variable "tagger_service_max_containers" {
  type = number
}

variable "tagger_service_max_requests_per_container" {
  type = number
}

variable "tagger_service_max_cpu" {
  type = number
}

variable "tagger_service_max_memory" {
  type = string
}

variable "dispatcher_pubsub_client_config" {
  type = object({
    pubsub_flow_control_max_outstanding_request_bytes = number # 10 MiB (10 * 1024 * 1024)
    pubsub_flow_control_max_outstanding_element_count = number
    pubsub_batching_element_count_threshold           = number
    pubsub_batching_request_byte_threshold            = number
    pubsub_batching_delay_threshold_millis            = number
    pubsub_retry_initial_retry_delay_millis           = number
    pubsub_retry_retry_delay_multiplier               = number
    pubsub_retry_max_retry_delay_seconds              = number
    pubsub_retry_initial_rpc_timeout_seconds          = number
    pubsub_retry_rpc_timeout_multiplier               = number
    pubsub_retry_max_rpc_timeout_seconds              = number
    pubsub_retry_total_timeout_seconds                = number
    pubsub_executor_thread_count_multiplier           = number
  })
}

variable "application_service_account_name" {
  type = string
}

variable "tagger_gcs_service_account_name" {
  type = string
}

variable "dlp_notifications_topic_name" {
  type = string
}

variable "retain_dlp_tagger_pubsub_messages" {
  type        = bool
  description = " Indicates whether to retain acknowledged messages. If true, then messages are not expunged from the subscription's backlog, even if they are acknowledged, until they fall out of the messageRetentionDuration window. Retaining messages enables the 'Replay' functionality."
}

variable "java_class_path_gcs_tagger_service" {
  type = string
}

variable "java_class_path_gcs_dispatcher_service" {
  type = string
}