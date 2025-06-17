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

variable "project" {
  type = string
}

variable "compute_region" {
  description = "GCP region to deploy compute resources (e.g. Cloud Run)"
  type        = string
}

variable "source_data_regions" {
  description = "Supported GCP regions for DLP inspection and tagging. These are the regions to run DLP jobs in and deploy policy tags taxonomies."
  type        = set(string)
}

variable "dlp_dataset_name" {
  type = string
}

variable "logging_dataset_name" {
  type = string
}

variable "auto_dlp_results_table_name" {
  type        = string
  description = "New table name to be created to hold DLP findings in the format 'table'"
}

variable "workflows_bq_name" {
  type = string
}

variable "workflows_bq_description" {
  type = string
}

variable "tagger_service_name" {
  type = string
}

variable "tagger_pubsub_topic" {
  type = string
}

variable "tagger_pubsub_sub" {
  type = string
}

# Images
variable "gar_docker_repo_name" {
  type = string
}

variable "image_name" {
  type = string
}


# for each domain in scope, these policy tags will be created in a domain-specific taxonomy
# and mapped in BQ configuration with the generated policy_tag_id. Each policy tag will be created
# under a parent node based on the 'classification' field
# info_type_category: "standard" or "custom". Standard types will be added to the DLP inspection template automatically.
# Custom types must be defined manually in th dlp inspection template
# INFO_TYPEs configured in the DLP inspection job MUST be mapped here. Otherwise, mapping to policy tag ids will fail
variable "classification_taxonomy" {
  type = list(object({
    info_type          = string
    info_type_category = string
    # (standard | custom)
    policy_tag                 = string
    classification             = string
    labels                     = optional(list(object({ key = string, value = string })), [])
    inspection_template_number = optional(number, 1)
    taxonomy_number            = optional(number, 1)
  }))
}

variable "domain_mapping" {
  type = list(object({
    project = string,
    domain  = string,
    datasets = list(object({
      name   = string,
      domain = string
    })) // leave empty if no dataset overrides is required for this project
  }))
  description = "Mapping between domains and GCP projects or BQ Datasets. Dataset-level mapping will overwrite project-level mapping for a given project."
}

variable "iam_mapping" {
  type        = map(map(list(string)))
  description = "Dictionary of mappings between domains/classification and IAM members to grant required permissions to read sensitive BQ columns belonging to that domain/classification"
}

variable "is_dry_run_tags" {
  type        = bool
  description = "Applying Policy Tags in the Tagger function (False) or just logging actions (True)"
}

variable "is_dry_run_labels" {
  type        = bool
  description = "Applying resource labels in the Tagger function (False) or just logging actions (True)"
}


variable "data_catalog_taxonomy_activated_policy_types" {
  type        = list(string)
  description = "A lis of policy types for the created taxonomy(s)"
}

# Tagger settings.
variable "tagger_service_timeout_seconds" {
  description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
  type        = number
}

variable "tagger_subscription_ack_deadline_seconds" {
  description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
  type        = number
}

variable "tagger_subscription_message_retention_duration" {
  description = "How long to retain unacknowledged messages in the subscription's backlog"
  type        = string
}

variable "taxonomy_name_suffix" {
  type        = string
  description = "Suffix added to taxonomy display name to make it unique within an org"
}

variable "terraform_data_deletion_protection" {
  type = bool
}

variable "retain_dlp_tagger_pubsub_messages" {
  type        = bool
  description = " Indicates whether to retain acknowledged messages. If true, then messages are not expunged from the subscription's backlog, even if they are acknowledged, until they fall out of the messageRetentionDuration window. Retaining messages enables the 'Replay' functionality."
}

variable "default_domain_name" {
  type        = string
  description = "default domain to use when domain_mapping is empty. This is used in deployments where only one domain is required and/or as a fallback for projects and datasets without explicit domain mapping."
}

variable "bq_existing_labels_regex" {
  type        = string
  description = "A regex used to match existing bucket labels to be deleted and re-created based on the newest DLP findings and info type mapping"
}

variable "promote_dlp_other_matches" {
  type        = bool
  description = "When set to true, the tagger service will include the 'other_matches' that DLP finds for a particular table to promote one policy tag per column"
}

variable "logging_table_name" {
  type = string
}

variable "bq_view_run_summary" {
  type = string
}

variable "info_type_map_file_path" {
  type = string
}

variable "resources_bucket_name" {
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

variable "tagger_bq_service_account_name" {
  type = string
}

variable "dlp_notifications_topic_name" {
  type = string
}

variable "java_class_path_bq_tagger_service" {
  type = string
}

variable "java_class_path_bq_dispatcher_service" {
  type = string
}