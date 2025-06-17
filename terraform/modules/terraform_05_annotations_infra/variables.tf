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

################################################################################
# Common-Required Variables
################################################################################

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

variable "source_data_regions" {
  description = "Supported GCP regions for DLP inspection and tagging. These are the regions to run DLP jobs in and deploy policy tags taxonomies."
  type        = set(string)
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
    policy_tag      = string
    classification  = string
    labels          = optional(list(object({ key = string, value = string })), [])
    taxonomy_number = optional(number, 1)
  }))
}

variable "services_container_image_name" {
  type        = string
  description = "Existing Container image name that contains the services used by Cloud Run and published in the host project. Example: annotations-services:latest"
}

################################################################################
# Common-Default Variables
################################################################################

variable "is_dry_run_labels" {
  type        = bool
  default     = true
  description = "Applying resource labels in the Tagger function (False) or just logging actions (True)"
}

variable "bigquery_dataset_name" {
  type    = string
  default = "annotations"
}

variable "log_sink_name" {
  type    = string
  default = "sc_bigquery_log_sink"
}

variable "gar_docker_repo_name" {
  type    = string
  default = "annotations"
}

variable "application_service_account_name" {
  type        = string
  description = "Name of the service account to run the application components"
  default     = "annotations-app"
}

variable "dlp_dataset_name" {
  type        = string
  description = "Existing BigQuery dataset that contains DLP discovery service findings"
  default     = "dlp_results"
}

variable "tagger_subscription_message_retention_duration" {
  description = "How long to retain unacknowledged messages in the subscription's backlog"
  type        = string
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions (e.g. Tagger issuing unnecessary BQ queries)
  # It also sets how long should we keep trying to process one run
  # min value must be at least equal to the ack_deadline_seconds
  # Tagger should have a relatively long retention to handle runs with large number of tables.
  default = "604800s" # 7 days (max)
}

variable "terraform_data_deletion_protection" {
  type        = bool
  default     = true
  description = "Prevents Terraform from deleting resources when the configuration is changed."
}

variable "retain_dlp_tagger_pubsub_messages" {
  type        = bool
  default     = true
  description = " Indicates whether to retain acknowledged messages. If true, then messages are not expunged from the subscription's backlog, even if they are acknowledged, until they fall out of the messageRetentionDuration window. Retaining messages enables the 'Replay' functionality."
}

variable "existing_labels_regex" {
  type        = string
  default     = "(?!)" // Negative lookahead with an empty pattern to never match labels
  description = "A regex used to match existing labels to be deleted and re-created based on the newest DLP findings and info type mapping"
}

################################################################################
# CommonServices Scalability params (defaults)
################################################################################

# Tagger Cloud Run settings.

variable "tagger_service_timeout_seconds" {
  description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
  type        = number
  # Tagger is using BQ batch jobs that might need time to start running and thus a relatively longer timeout
  default = 540
  # 9m
}

variable "tagger_subscription_ack_deadline_seconds" {
  description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
  type        = number
  // This should be higher than the service_timeout_seconds to avoid retrying messages that are still processing
  // range is 10 to 600
  default = 600
  # 10m
}

# Dispatcher Scalability params

variable "dispatcher_cloud_batch_memory_mib" {
  type    = number
  default = 1000
}

variable "dispatcher_cloud_batch_cpu_millis" {
  type    = number
  default = 2000
}

variable "dispatcher_cloud_batch_max_run_duration_seconds" {
  type    = number
  default = 60 * 60 * 1 # 1 hour
}

# Pubsub client configurations used by the dispatcher
variable "dispatcher_pubsub_client_config" {
  description = "Pub/Sub configuration parameters."
  type = object({
    pubsub_flow_control_max_outstanding_request_bytes = optional(number, 10485760) # 10 MiB (10 * 1024 * 1024)
    pubsub_flow_control_max_outstanding_element_count = optional(number, 1000)
    pubsub_batching_element_count_threshold           = optional(number, 100)
    pubsub_batching_request_byte_threshold            = optional(number, 1000000)
    pubsub_batching_delay_threshold_millis            = optional(number, 1)
    pubsub_retry_initial_retry_delay_millis           = optional(number, 100)
    pubsub_retry_retry_delay_multiplier               = optional(number, 2.0)
    pubsub_retry_max_retry_delay_seconds              = optional(number, 60)
    pubsub_retry_initial_rpc_timeout_seconds          = optional(number, 1)
    pubsub_retry_rpc_timeout_multiplier               = optional(number, 1.0)
    pubsub_retry_max_rpc_timeout_seconds              = optional(number, 600)
    pubsub_retry_total_timeout_seconds                = optional(number, 600)
    pubsub_executor_thread_count_multiplier           = optional(number, 5)
  })
  default = {}
}

################################################################################
# BQ Discovery stack variables (Defaults)
################################################################################


variable "auto_dlp_results_table_name" {
  type        = string
  description = "New table name to be created to hold DLP findings in the format 'table'"
  default     = "dlp_discovery_services_bq_results"
}

variable "tagger_bq_service_account_name" {
  type    = string
  default = "annotations-bq"
}

variable "workflows_bq_name" {
  type    = string
  default = "bigquery_tables_re_annotation_trigger"
}

variable "workflows_bq_description" {
  type    = string
  default = "Trigger (re)annotation process for BigQuery tables based on DLP findings"
}

variable "tagger_service_name" {
  type    = string
  default = "tagger-bq"
}

variable "tagger_pubsub_topic" {
  type    = string
  default = "tagger_bq_topic"
}

variable "tagger_pubsub_sub" {
  type    = string
  default = "tagger_bq_push_sub"
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
  default     = []
  description = "Mapping between domains and GCP projects or BQ Datasets. Dataset-level mapping will overwrite project-level mapping for a given project."
}

variable "iam_mapping" {
  type        = map(map(list(string)))
  default     = {}
  description = "Dictionary of mappings between domains/classification and IAM members to grant required permissions to read sensitive BQ columns belonging to that domain/classification"
}

// Use ["FINE_GRAINED_ACCESS_CONTROL"] to restrict IAM access on tagged columns.
// Use [] NOT to restrict IAM access.
variable "data_catalog_taxonomy_activated_policy_types" {
  type        = list(string)
  default     = []
  description = "A lis of policy types for the created taxonomy(s)"
}

variable "taxonomy_name_suffix" {
  type        = string
  default     = ""
  description = "Suffix added to taxonomy display name to make it unique within an org"
}

variable "is_dry_run_tags" {
  type        = bool
  default     = true
  description = "Applying Policy Tags in the Tagger function (False) or just logging actions (True)"
}

variable "default_domain_name" {
  type        = string
  default     = "annotations"
  description = "default domain to use when domain_mapping is empty. This is used in deployments where only one domain is required and/or as a fallback for projects and datasets without explicit domain mapping."
}

variable "promote_dlp_other_matches" {
  type        = bool
  default     = false
  description = "When set to true, the tagger service will include the 'other_matches' that DLP finds for a particular table to promote one policy tag per column"
}

# Tagger Scalability params

# Discovery Tagging:
#   BQ Tagger hits the DLP API (get data profile), and BQ API (update table)
#   DLP API: 600 requests per minute
#   BQ API: NA
# Dispatcher Tagging:
#   Only hits the BQ API to add labels to buckets

variable "tagger_bq_service_max_containers" {
  type    = number
  default = 1
}

variable "tagger_bq_service_max_requests_per_container" {
  type    = number
  default = 80
}

variable "tagger_bq_service_max_cpu" {
  type    = number
  default = 2
}

variable "tagger_bq_service_max_memory" {
  type    = string
  default = "4Gi"
}

variable "dlp_for_bq_pubsub_topic_name" {
  type    = string
  default = "dlp_results_for_bq_topic"
}

variable "java_class_path_bq_tagger_service" {
  type = string
  default = "com.google.cloud.oss.solutions.annotations.apps.bigquery.BigQueryTaggerController"
}

variable "java_class_path_bq_dispatcher_service" {
  type = string
  default = "com.google.cloud.oss.solutions.annotations.apps.dispatcher.BigQueryDispatcher"
}

################################################################################
# GCS Discovery stack variables (Defaults)
################################################################################

## ### Stack specific variables - Default value variables

variable "dlp_gcs_bq_results_table_name" {
  type        = string
  description = "Name of the table that DLP will create to save the findings. This will be created in the solution dataset"
  default     = "dlp_discovery_services_gcs_results"
}

variable "workflows_gcs_name" {
  type    = string
  default = "gcs_buckets_re_annotation_trigger"
}

variable "workflows_gcs_description" {
  type    = string
  default = "Trigger (re)annotation process for Cloud Storage buckets based on DLP findings"
}

##### GCS Tagger Service ######

variable "tagger_gcs_service_account_name" {
  type    = string
  default = "annotations-gcs"
}

variable "tagger_gcs_service_name" {
  type    = string
  default = "tagger-gcs"
}

variable "tagger_gcs_pubsub_topic" {
  type    = string
  default = "tagger_gcs_topic"
}

variable "tagger_gcs_pubsub_sub" {
  type    = string
  default = "tagger_gcs_push_sub"
}

# Tagger Scalability params

# Discovery Tagging:
#   GCS Tagger hits the DLP API (get file store profile), and Cloud Storage API (update bucket)
#   DLP API: 600 requests per minute
#   Storage API: NA
# Dispatcher Tagging:
#   Only hits the Storage API to add labels to buckets

variable "tagger_gcs_service_max_containers" {
  type    = number
  default = 1
}

variable "tagger_gcs_service_max_requests_per_container" {
  type    = number
  default = 80
}

variable "tagger_gcs_service_max_cpu" {
  type    = number
  default = 2
}

variable "tagger_gcs_service_max_memory" {
  type    = string
  default = "4Gi"
}

variable "dlp_for_gcs_pubsub_topic_name" {
  type    = string
  default = "dlp_results_for_gcs_topic"
}

variable "java_class_path_gcs_tagger_service" {
  type = string
  default = "com.google.cloud.oss.solutions.annotations.apps.storage.GcsTaggerController"
}

variable "java_class_path_gcs_dispatcher_service" {
  type = string
  default = "com.google.cloud.oss.solutions.annotations.apps.dispatcher.GcsDispatcher"
}