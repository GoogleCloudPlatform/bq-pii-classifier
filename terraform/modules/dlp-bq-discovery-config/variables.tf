variable "project" {
  type = string
}

variable "dlp_bq_scan_org_id" {
  type = string
}

variable "data_region" {
  type = string
}

variable "bigquery_dataset_name" {
  type = string
}

variable "auto_dlp_results_table_name" {
  type = string
  description = "New table name to be created to hold DLP findings in the format 'table'"
}

variable "dlp_bq_scan_folder_id" {
  type = string
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

variable "pubsub_tagger_topic_id" {
  type = string
}