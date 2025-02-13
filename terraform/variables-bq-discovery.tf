
variable "dlp_bq_scan_org_id" {
  type = string
  default = null
}

variable "dlp_bq_scan_folder_id" {
  type = string
  default = null
}

variable "dlp_bq_create_configuration_in_paused_state" {
  type = bool
  description = "When set to true, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to false, the discovery scan will start running upon creation"
  default = true
}

variable "dlp_bq_project_id_regex" {
  type        = string
  description = "Regex for project ids to be covered by the DLP scan for BigQuery. For organization-level configuration, if unset, will match all projects"
  default     = ".*"
}

variable "dlp_bq_dataset_regex" {
  type        = string
  description = "Regex to test the dataset name against during the DLP scan for BigQuery. if unset, this property matches all datasets"
  default     = ".*"
}

variable "dlp_bq_table_regex" {
  type        = string
  description = "Regex to test the table name against during the DLP scan for BigQuery.  if unset, this property matches all tables"
  default     = ".*"
}

variable "dlp_bq_table_types" {
  type = list(string)
  description = "Restrict dlp discovery service for BigQuery to specific table types"
  default = ["BIG_QUERY_TABLE_TYPE_TABLE", "BIG_QUERY_TABLE_TYPE_EXTERNAL_BIG_LAKE"]
}

variable "dlp_bq_reprofile_on_table_schema_update_frequency" {
  type = string
  description = "How frequently data profiles can be updated when a table schema is modified (i.e. columns). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
  default = "UPDATE_FREQUENCY_NEVER"
}

variable "dlp_bq_reprofile_on_table_data_update_frequency" {
  type = string
  description = "How frequently data profiles can be updated when a table data is modified (i.e. rows). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
  default = "UPDATE_FREQUENCY_NEVER"
}

variable "dlp_bq_reprofile_on_inspection_template_update_frequency" {
  type = string
  description = "How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
  default = "UPDATE_FREQUENCY_NEVER"
}

variable "dlp_bq_reprofile_on_schema_update_types" {
  type = list(string)
  description = "The type of events to consider when deciding if the table's schema has been modified and should have the profile updated. Defaults to NEW_COLUMN. Each value may be one of: SCHEMA_NEW_COLUMNS, SCHEMA_REMOVED_COLUMNS"
  default = ["SCHEMA_NEW_COLUMNS"]
}

variable "dlp_bq_reprofile_on_table_data_update_types" {
  type = list(string)
  description = "The type of events to consider when deciding if the table has been modified and should have the profile updated. Defaults to MODIFIED_TIMESTAMP Each value may be one of: TABLE_MODIFIED_TIMESTAMP"
  default = ["TABLE_MODIFIED_TIMESTAMP"]
}