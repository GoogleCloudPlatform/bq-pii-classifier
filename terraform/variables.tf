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
  description = "GCP region to deploy compute resources (e.g. Cloud Run)"
  type = string
}

variable "data_region" {
  description = "GCP region to store application data (e.g. DLP results, logs, etc)"
  type = string
}

variable "source_data_regions" {
  description = "Supported GCP regions for DLP inspection and tagging. These are the regions to run DLP jobs in and deploy policy tags taxonomies."
  type = set(string)
}

variable "bigquery_dataset_name" {
  type = string
  default = "bq_pii_classifier"
}

variable "log_sink_name" {
  type = string
  default = "sc_bigquery_log_sink"
}



# Images
variable "gar_docker_repo_name" {
  type = string
  default = "bq-pii-classifier"
}

# for each domain in scope, these policy tags will be created in a domain-specific taxonomy
# and mapped in BQ configuration with the generated policy_tag_id. Each policy tag will be created
# under a parent node based on the 'classification' field
# info_type_category: "standard" or "custom". Standard types will be added to the DLP inspection template automatically.
# Custom types must be defined manually in th dlp inspection template
# INFO_TYPEs configured in the DLP inspection job MUST be mapped here. Otherwise, mapping to policy tag ids will fail
variable "classification_taxonomy" {
  type = list(object({
    info_type = string
    info_type_category = string
    # (standard | custom)
    policy_tag = string
    classification = string
    labels = optional(list(object({key = string, value = string})), [])
    inspection_template_number = optional(number, 1)
    taxonomy_number = optional(number, 1)
  }))
}

variable "custom_info_types_dictionaries" {
  type = list(object({
    name = string
    likelihood = string
    dictionary =list(string)
  }))
  default = []
}

variable "custom_info_types_regex" {
  type = list(object({
    name = string
    likelihood = string
    regex = string
  }))
  default = []
}

variable "terraform_service_account_email" {
  type = string
  description = "The service account email to be used by terraform to deploy to GCP"
}


variable "is_dry_run_labels" {
  type = bool
  default = false
  description = "Applying resource labels in the Tagger function (False) or just logging actions (True)"
}


variable "gcs_flags_bucket_name" {
  type = string
  default = "bq-pii-classifier-flags"
}

# Dispatcher settings.
variable "dispatcher_service_timeout_seconds" {
  description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
  type = number
  # Dispatcher might need relatively long time to process large BigQuery scan scopes
  default = 3600 # 60m  # 540 # 9m

}

variable "dispatcher_subscription_ack_deadline_seconds" {
  description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
  type = number
  // This should be higher than the service_timeout_seconds to avoid retrying messages that are still processing
  // range is 10 to 600
  default = 600
  # 10m
}

variable "dispatcher_subscription_message_retention_duration" {
  description = "How long to retain unacknowledged messages in the subscription's backlog"
  type = string
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions (e.g. Tagger issuing unnecessary BQ queries)
  # min value must be at least equal to the ack_deadline_seconds
  # Dispatcher should have the shortest retention possible because we want to avoid retries (on the app level as well)
  default = "600s"
  # 10m
}

# Tagger settings.
variable "tagger_service_timeout_seconds" {
  description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
  type = number
  # Tagger is using BQ batch jobs that might need time to start running and thus a relatively longer timeout
  default = 540
  # 9m
}

variable "tagger_subscription_ack_deadline_seconds" {
  description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
  type = number
  // This should be higher than the service_timeout_seconds to avoid retrying messages that are still processing
  // range is 10 to 600
  default = 600
  # 10m
}

variable "tagger_subscription_message_retention_duration" {
  description = "How long to retain unacknowledged messages in the subscription's backlog"
  type = string
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions (e.g. Tagger issuing unnecessary BQ queries)
  # It also sets how long should we keep trying to process one run
  # min value must be at least equal to the ack_deadline_seconds
  # Tagger should have a relatively long retention to handle runs with large number of tables.
  default = "86400s"
  # 24h
}



variable "terraform_data_deletion_protection" {
  type = bool
  # Allow destroying BQ datasets and GCS buckets. Set to true for production use
  default = false
}

variable "retain_dlp_tagger_pubsub_messages" {
  type = bool
  default = true
  description = " Indicates whether to retain acknowledged messages. If true, then messages are not expunged from the subscription's backlog, even if they are acknowledged, until they fall out of the messageRetentionDuration window. Retaining messages enables the 'Replay' functionality."
}


variable "supported_stacks" {
  type = set(string)
  default = ["BIGQUERY_DISCOVERY"]
  description = "Define which source systems would be scanned by Cloud DLP, using which methods (inspection vs discovery). Values are BIGQUERY_DISCOVERY, GCS_DISCOVERY. Only one stack is allowed per source system."
  validation {
    condition = anytrue([
    for item in var.supported_stacks: contains(["BIGQUERY_DISCOVERY", "GCS_DISCOVERY"], item)
    ])
    error_message = "The variable `supported_stacks` must contain either 'BIGQUERY_DISCOVERY', and optionally 'GCS_DISCOVERY'."
  }
}

variable "deploy_dlp_inspection_template_to_global_region" {
  type = bool
  default = false
  description = "When set to `True`, DLP inspection template will be deployed to the 'global' region in addition to regions set in source data regions. This allows DLP to scan resources in any region."
}

variable "dispatcher_service_max_cpu" {
  type = number
  default = 8
}

variable "dispatcher_service_max_memory" {
  type = string
  default = "16Gi"
}

variable "image_name" {
  type = string
  default = "bq-pii-classifier-services:latest"
}

variable "org_id" {
  type = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
}

### Tags

variable "dlp_tag_sensitivity_level_key_name" {
  type = string
  default = "dlp_sensitivity_level"
}

variable "dlp_tag_high_sensitivity_value_name" {
  type = string
  default = "high"
}

variable "dlp_tag_moderate_sensitivity_value_name" {
  type = string
  default = "moderate"
}

variable "dlp_tag_low_sensitivity_value_name" {
  type = string
  default = "low"
}