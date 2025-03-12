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

variable "auto_dlp_results_table_name" {
  type = string
  description = "New table name to be created to hold DLP findings in the format 'table'"
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

variable "sa_workflows_bq" {
  type = string
}

variable "workflows_bq_name" {
  type = string
}

variable "workflows_bq_description" {
  type = string
}

variable "sa_bq_remote_func_get_policy_tags" {
  type = string
}

variable "tagging_dispatcher_service_name" {
  type = string
}

variable "tagger_service_name" {
  type = string
}

variable "bq_remote_func_get_policy_tags_name" {
  type = string
}


variable "tagging_dispatcher_pubsub_topic" {
  type = string
}

variable "tagging_dispatcher_pubsub_sub" {
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

variable "is_dry_run_tags" {
  type = bool
  description = "Applying Policy Tags in the Tagger function (False) or just logging actions (True)"
}

variable "is_dry_run_labels" {
  type = bool
  description = "Applying resource labels in the Tagger function (False) or just logging actions (True)"
}


variable "data_catalog_taxonomy_activated_policy_types" {
  type = list(string)
  description = "A lis of policy types for the created taxonomy(s)"
}

variable "gcs_flags_bucket_name" {
  type = string
}

# Dispatcher settings.
variable "dispatcher_service_timeout_seconds" {
  description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
  type = number
}

variable "dispatcher_subscription_ack_deadline_seconds" {
  description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
  type = number
}

variable "dispatcher_subscription_message_retention_duration" {
  description = "How long to retain unacknowledged messages in the subscription's backlog"
  type = string
}

# Tagger settings.
variable "tagger_service_timeout_seconds" {
  description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
  type = number
}

variable "tagger_subscription_ack_deadline_seconds" {
  description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
  type = number
}

variable "tagger_subscription_message_retention_duration" {
  description = "How long to retain unacknowledged messages in the subscription's backlog"
  type = string
}

variable "taxonomy_name_suffix" {
  type = string
  description = "Suffix added to taxonomy display name to make it unique within an org"
}

variable "terraform_data_deletion_protection" {
  type = bool
}

variable "retain_dlp_tagger_pubsub_messages" {
  type = bool
  description = " Indicates whether to retain acknowledged messages. If true, then messages are not expunged from the subscription's backlog, even if they are acknowledged, until they fall out of the messageRetentionDuration window. Retaining messages enables the 'Replay' functionality."
}

variable "datastore_database_name" {
  type    = string
}

variable "default_domain_name" {
  type = string
  description = "default domain to use when domain_mapping is empty. This is used in deployments where only one domain is required and/or as a fallback for projects and datasets without explicit domain mapping."
}

variable "bq_existing_labels_regex" {
  type = string
  description = "A regex used to match existing bucket labels to be deleted and re-created based on the newest DLP findings and info type mapping"
}

variable "deploy_dlp_inspection_template_to_global_region" {
  type = bool
  description = "When set to `True`, DLP inspection template will be deployed to the 'global' region in addition to regions set in source data regions. This allows DLP to scan resources in any region."
}

variable "dispatcher_service_max_cpu" {
  type = number
}

variable "dispatcher_service_max_memory" {
  type = string
}

variable "promote_dlp_other_matches" {
  type = bool
  description = "When set to true, the tagger service will include the 'other_matches' that DLP finds for a particular table to promote one policy tag per column"
}

variable "dlp_bq_scan_org_id" {
  type = string
}

variable "dlp_bq_scan_folder_id" {
  type = string
}

variable "dlp_bq_create_configuration_in_paused_state" {
  type = bool
  description = "When set to true, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to false, the discovery scan will start running upon creation"
}

variable "dlp_bq_project_id_regex" {
  type        = string
  description = "Regex for project ids to be covered by the DLP scan for BigQuery. For organization-level configuration, if unset, will match all projects"
}

variable "dlp_bq_dataset_regex" {
  type        = string
  description = "Regex to test the dataset name against during the DLP scan for BigQuery. if unset, this property matches all datasets"
}

variable "dlp_bq_table_regex" {
  type        = string
  description = "Regex to test the table name against during the DLP scan for BigQuery.  if unset, this property matches all tables"
}

variable "dlp_bq_table_types" {
  type = list(string)
  description = "Restrict dlp discovery service for BigQuery to specific table types"
}

variable "dlp_bq_reprofile_on_table_schema_update_frequency" {
  type = string
  description = "How frequently data profiles can be updated when a table schema is modified (i.e. columns). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
}

variable "dlp_bq_reprofile_on_table_data_update_frequency" {
  type = string
  description = "How frequently data profiles can be updated when a table data is modified (i.e. rows). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
}

variable "dlp_bq_reprofile_on_inspection_template_update_frequency" {
  type = string
  description = "How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
}

variable "dlp_bq_reprofile_on_schema_update_types" {
  type = list(string)
  description = "The type of events to consider when deciding if the table's schema has been modified and should have the profile updated. Defaults to NEW_COLUMN. Each value may be one of: SCHEMA_NEW_COLUMNS, SCHEMA_REMOVED_COLUMNS"
}

variable "dlp_bq_reprofile_on_table_data_update_types" {
  type = list(string)
  description = "The type of events to consider when deciding if the table has been modified and should have the profile updated. Defaults to MODIFIED_TIMESTAMP Each value may be one of: TABLE_MODIFIED_TIMESTAMP"
}

variable "logging_table_name" {
  type = string
}

variable "bq_view_run_summary" {
  type = string
}


variable "info_types_map" {
  // map( info_type_name: str, info_type_meta_data: object) where info_type_meta_data is an object( classification:str, labels: list) and labels is a list of key-value pairs represented as a map
  type = map(object({classification = string, labels = list(map(string))}))
}

variable "dlp_inspection_templates_ids_list" {
  type = list(string)
}