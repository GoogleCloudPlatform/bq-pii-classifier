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

variable "dlp_agent_project_id" {
  type = string
}

variable "publishing_project" {
  type = string
}

variable "dlp_bq_scan_parent_type" {
  type = string
  description = "The GCP organization hierarchy node to deploy the discovery configuration to. Allowed values [project, organization]"
  validation {
    condition     = contains(["organization", "project"], var.dlp_bq_scan_parent_type)
    error_message = "The 'dlp_bq_scan_parent_type' must be either 'organization' or 'project'."
  }
}

variable "dlp_bq_scan_parent_id" {
  type = string
  description = "Organization number or project id of the dlp_gcs_scan_parent_type"
  validation {
    condition     = var.dlp_bq_scan_parent_type != "project" || var.dlp_bq_scan_parent_id == var.dlp_agent_project_id
    error_message = "If 'dlp_gcs_scan_parent_type' is 'project', then 'dlp_gcs_scan_parent_id' must be equal to 'dlp_agent_project_id'."
  }
}

variable "dlp_bq_scan_target_entity_id" {
  type        = string
  description = "GCP folder ID or project ID that will be scanned by DLP discovery service for BigQuery. In case of dlp_bq_scan_parent_type = project, the following fields must be the same: dlp_bq_scan_target_entity_id, dlp_bq_scan_parent_id and dlp_agent_project_id"
  validation {
    condition     = var.dlp_bq_scan_parent_type != "project" || var.dlp_bq_scan_parent_id == var.dlp_bq_scan_target_entity_id
    error_message = "If 'dlp_bq_scan_parent_type' is 'project', then 'dlp_bq_scan_parent_id' must be equal to 'dlp_bq_scan_target_entity_id'."
  }
}

variable "data_region" {
  type = string
}

variable "bigquery_dataset_name" {
  type = string
}

variable "auto_dlp_results_table_name" {
  type        = string
  description = "New table name to be created to hold DLP findings in the format 'table'"
}

variable "dlp_inspection_templates_ids_list" {
  type = list(string)
}

## Tags
variable "dlp_tag_high_sensitivity_id" {
  type = string
}

variable "dlp_tag_moderate_sensitivity_id" {
  type = string
}

variable "dlp_tag_low_sensitivity_id" {
  type = string
}

variable "dlp_bq_apply_tags" {
  type = bool
}


variable "dlp_bq_create_configuration_in_paused_state" {
  type        = bool
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
  type        = list(string)
  description = "Restrict dlp discovery service for BigQuery to specific table types"
}

variable "dlp_bq_reprofile_on_table_schema_update_frequency" {
  type        = string
  description = "How frequently data profiles can be updated when a table schema is modified (i.e. columns). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
}

variable "dlp_bq_reprofile_on_table_data_update_frequency" {
  type        = string
  description = "How frequently data profiles can be updated when a table data is modified (i.e. rows). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
}

variable "dlp_bq_reprofile_on_inspection_template_update_frequency" {
  type        = string
  description = "How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
}

variable "dlp_bq_reprofile_on_schema_update_types" {
  type        = list(string)
  description = "The type of events to consider when deciding if the table's schema has been modified and should have the profile updated. Defaults to NEW_COLUMN. Each value may be one of: SCHEMA_NEW_COLUMNS, SCHEMA_REMOVED_COLUMNS"
}

variable "dlp_bq_reprofile_on_table_data_update_types" {
  type        = list(string)
  description = "The type of events to consider when deciding if the table has been modified and should have the profile updated. Defaults to MODIFIED_TIMESTAMP Each value may be one of: TABLE_MODIFIED_TIMESTAMP"
}

variable "pubsub_tagger_topic_id" {
  type = string
}

variable "pubsub_errors_topic_id" {
  type    = string
}