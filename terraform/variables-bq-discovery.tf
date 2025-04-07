
variable "auto_dlp_results_table_name" {
  type = string
  description = "New table name to be created to hold DLP findings in the format 'table'"
  default = "auto_dlp_results"
}

variable "sa_tagging_dispatcher" {
  type = string
  default = "tag-dispatcher"
}

variable "sa_tagging_dispatcher_tasks" {
  type = string
  default = "tag-dispatcher-tasks"
}

variable "sa_tagger" {
  type = string
  default = "tagger"
}

variable "sa_tagger_tasks" {
  type = string
  default = "tagger-tasks"
}

variable "sa_workflows_bq" {
  type = string
  default = "workflows-bq"
}

variable "workflows_bq_name" {
  type = string
  default = "bigquery_tables_re_annotation_trigger"
}

variable "workflows_bq_description" {
  type = string
  default = "Trigger (re)annotation process for BigQuery tables based on DLP findings"
}

variable "sa_bq_remote_func_get_policy_tags" {
  type = string
  default = "sa-func-get-policy-tags"
}


variable "tagging_dispatcher_service_name" {
  type = string
  default = "s1a-tagging-dispatcher"
}

variable "tagger_service_name" {
  type = string
  default = "s3-tagger"
}

variable "bq_remote_func_get_policy_tags_name" {
  type = string
  default = "get_table_policy_tags"
}


variable "tagging_dispatcher_pubsub_topic" {
  type = string
  default = "tagging_dispatcher_topic"
}

variable "tagging_dispatcher_pubsub_sub" {
  type = string
  default = "tagging_dispatcher_push_sub"
}

variable "tagger_pubsub_topic" {
  type = string
  default = "tagger_topic"
}

variable "tagger_pubsub_sub" {
  type = string
  default = "tagger_push_sub"
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
  default = []
  description = "Mapping between domains and GCP projects or BQ Datasets. Dataset-level mapping will overwrite project-level mapping for a given project."
}

variable "iam_mapping" {
  type = map(map(list(string)))
  default = {}
  description = "Dictionary of mappings between domains/classification and IAM members to grant required permissions to read sensitive BQ columns belonging to that domain/classification"
}

// Use ["FINE_GRAINED_ACCESS_CONTROL"] to restrict IAM access on tagged columns.
// Use [] NOT to restrict IAM access.
variable "data_catalog_taxonomy_activated_policy_types" {
  type = list(string)
  default = []
  description = "A lis of policy types for the created taxonomy(s)"
}

variable "taxonomy_name_suffix" {
  type = string
  default = ""
  description = "Suffix added to taxonomy display name to make it unique within an org"
}

variable "datastore_database_name" {
  type    = string
  default = "(default)"
}

variable "is_dry_run_tags" {
  type = bool
  default = false
  description = "Applying Policy Tags in the Tagger function (False) or just logging actions (True)"
}

variable "default_domain_name" {
  type = string
  default = "default_domain"
  description = "default domain to use when domain_mapping is empty. This is used in deployments where only one domain is required and/or as a fallback for projects and datasets without explicit domain mapping."
}

variable "bq_existing_labels_regex" {
  type = string
  default = "(?!)" // Negative lookahead with an empty pattern to never match labels
  description = "A regex used to match existing bucket labels to be deleted and re-created based on the newest DLP findings and info type mapping"
}

variable "promote_dlp_other_matches" {
  type = bool
  default = false
  description = "When set to true, the tagger service will include the 'other_matches' that DLP finds for a particular table to promote one policy tag per column"
}

variable "dlp_bq_discovery_configurations" {
  type = list(object({

    # GCP folder to scan
    folder_id                                         = number

    # Regex for project ids to be covered by the DLP scan for BigQuery. For organization-level configuration, if unset, will match all projects
    project_id_regex                                  = optional(string, ".*")

    # Regex to test the dataset name against during the DLP scan for BigQuery. if unset, this property matches all datasets
    dataset_regex                                     = optional(string, ".*")

    # Regex to test the table name against during the DLP scan for BigQuery.  if unset, this property matches all tables
    table_regex                                       = optional(string, ".*")

    # When set to true, DLP discovery service will attach pre-existing data sensitivity levels tags to BigQuery tables
    apply_tags                                        = optional(bool, false)

    # dlp_bq_create_configuration_in_paused_state
    create_configuration_in_paused_state              = optional(bool, true)

    # Restrict dlp discovery service for BigQuery to specific table types
    table_types = optional(list(string), ["BIG_QUERY_TABLE_TYPE_TABLE", "BIG_QUERY_TABLE_TYPE_EXTERNAL_BIG_LAKE"])

    # How frequently data profiles can be updated when a table schema is modified (i.e. columns). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
    reprofile_frequency_on_table_schema_update        = optional(string, "UPDATE_FREQUENCY_NEVER")

    # How frequently data profiles can be updated when a table data is modified (i.e. rows). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
    reprofile_frequency_on_table_data_update          = optional(string, "UPDATE_FREQUENCY_NEVER")

    # How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
    reprofile_frequency_on_inspection_template_update = optional(string, "UPDATE_FREQUENCY_NEVER")

    # The type of events to consider when deciding if the table's schema has been modified and should have the profile updated. Defaults to NEW_COLUMN. Each value may be one of: SCHEMA_NEW_COLUMNS, SCHEMA_REMOVED_COLUMNS
    reprofile_types_on_schema_update = optional(list(string), ["SCHEMA_NEW_COLUMNS"])

    # The type of events to consider when deciding if the table has been modified and should have the profile updated. Defaults to MODIFIED_TIMESTAMP Each value may be one of: TABLE_MODIFIED_TIMESTAMP
    reprofile_types_on_table_data_update = optional(list(string), ["TABLE_MODIFIED_TIMESTAMP"])
  }))
}