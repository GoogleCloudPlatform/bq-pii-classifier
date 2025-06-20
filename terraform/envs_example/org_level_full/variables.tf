variable "terraform_service_account_email" {
  type        = string
  description = "Serviced account to be used by Terraform to deploy resources"
}

variable "org_id" {
  type        = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
}

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

variable "terraform_data_deletion_protection" {
  type        = bool
  description = "When set to `True`, Terraform will not delete data assets like buckets and BQ datasets"
}

variable "source_data_regions" {
  description = "Supported GCP regions for DLP inspection and tagging. These are the regions to run DLP jobs in and deploy policy tags taxonomies."
  type        = set(string)
}

variable "services_container_image_name" {
  type        = string
  description = "Existing Container image name that contains the services used by Cloud Run and published in the host project. Example: annotations-services:latest"
}

########################################################################################################################
#                                              DLP module variables
########################################################################################################################

variable "custom_info_types_dictionaries" {
  type = list(object({
    name                       = string
    likelihood                 = string
    dictionary                 = list(string)
    inspection_template_number = optional(number, 1)
  }))
}

variable "custom_info_types_regex" {
  type = list(object({
    name                       = string
    likelihood                 = string
    regex                      = string
    inspection_template_number = optional(number, 1)
  }))
}

variable "built_in_info_types" {
  type = list(object({
    info_type                  = string
    inspection_template_number = optional(number, 1)
  }))
}

variable "dlp_gcs_discovery_configurations" {
  type = list(object({

    // [organization, project]
    parent_type = string

    // organization number or project id
    parent_id = string

    # Folder id or project id to be scanned. In case of parent_type = project, parent_id and target_id must be equal
    target_id = string

    # Regex for project ids to be covered by the DLP scan of GCS buckets. For organization-level configuration, if unset, will match all projects
    project_id_regex = optional(string, ".*")

    # Regex to test the bucket name against during the DLP scan. If empty, all buckets match
    bucket_name_regex = optional(string, ".*")

    # When set to true, DLP discovery service will attach pre-existing data sensitivity levels tags to buckets
    apply_tags = optional(bool, false)

    # When set to true, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to false, the discovery scan will start running upon creation
    create_configuration_in_paused_state = optional(bool, true)

    # If you set this field, profiles are refreshed at this frequency regardless of whether the underlying data have changes. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY
    reprofile_frequency = optional(string, "UPDATE_FREQUENCY_NEVER")

    # How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
    reprofile_frequency_on_inspection_template_update = optional(string, "UPDATE_FREQUENCY_NEVER")

    # Only objects with the specified attributes will be scanned. Defaults to [ALL_SUPPORTED_BUCKETS] if unset. Each value may be one of: ALL_SUPPORTED_BUCKETS, AUTOCLASS_DISABLED, AUTOCLASS_ENABLED.
    included_bucket_attributes = optional(list(string), ["ALL_SUPPORTED_BUCKETS"])

    # Only objects with the specified attributes will be scanned. If an object has one of the specified attributes but is inside an excluded bucket, it will not be scanned. Defaults to [ALL_SUPPORTED_OBJECTS]. A profile will be created even if no objects match the included_object_attributes. Each value may be one of: ALL_SUPPORTED_OBJECTS, STANDARD, NEARLINE, COLDLINE, ARCHIVE, REGIONAL, MULTI_REGIONAL, DURABLE_REDUCED_AVAILABILITY."
    included_object_attributes = optional(list(string), ["ALL_SUPPORTED_OBJECTS"])
  }))
}

variable "dlp_bq_discovery_configurations" {
  type = list(object({

    // [organization, project]
    parent_type = string

    // organization number or project id
    parent_id = string

    # Folder id or project id to be scanned. In case of parent_type = project, parent_id and target_id must be equal
    target_id = string

    # Regex for project ids to be covered by the DLP scan for BigQuery. For organization-level configuration, if unset, will match all projects
    project_id_regex = optional(string, ".*")

    # Regex to test the dataset name against during the DLP scan for BigQuery. if unset, this property matches all datasets
    dataset_regex = optional(string, ".*")

    # Regex to test the table name against during the DLP scan for BigQuery.  if unset, this property matches all tables
    table_regex = optional(string, ".*")

    # When set to true, DLP discovery service will attach pre-existing data sensitivity levels tags to BigQuery tables
    apply_tags = optional(bool, false)

    # dlp_bq_create_configuration_in_paused_state
    create_configuration_in_paused_state = optional(bool, true)

    # Restrict dlp discovery service for BigQuery to specific table types
    table_types = optional(list(string), ["BIG_QUERY_TABLE_TYPE_TABLE", "BIG_QUERY_TABLE_TYPE_EXTERNAL_BIG_LAKE"])

    # How frequently data profiles can be updated when a table schema is modified (i.e. columns). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
    reprofile_frequency_on_table_schema_update = optional(string, "UPDATE_FREQUENCY_NEVER")

    # How frequently data profiles can be updated when a table data is modified (i.e. rows). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
    reprofile_frequency_on_table_data_update = optional(string, "UPDATE_FREQUENCY_NEVER")

    # How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
    reprofile_frequency_on_inspection_template_update = optional(string, "UPDATE_FREQUENCY_NEVER")

    # The type of events to consider when deciding if the tables schema has been modified and should have the profile updated. Defaults to NEW_COLUMN. Each value may be one of: SCHEMA_NEW_COLUMNS, SCHEMA_REMOVED_COLUMNS
    reprofile_types_on_schema_update = optional(list(string), ["SCHEMA_NEW_COLUMNS"])

    # The type of events to consider when deciding if the table has been modified and should have the profile updated. Defaults to MODIFIED_TIMESTAMP Each value may be one of: TABLE_MODIFIED_TIMESTAMP
    reprofile_types_on_table_data_update = optional(list(string), ["TABLE_MODIFIED_TIMESTAMP"])
  }))
}

variable "deploy_dlp_inspection_template_to_global_region" {
  type        = bool
  description = "When set to `True`, DLP inspection template will be deployed to the 'global' region in addition to regions set in source data regions. This allows DLP to scan resources in any region."
}

########################################################################################################################
#                                              Tags module variables
########################################################################################################################

variable "dlp_tag_sensitivity_level_key_name" {
  type = string
}

variable "ignore_dlp_sensitivity_key_name" {
  type = string
}

########################################################################################################################
#                                              Annotations module variables
########################################################################################################################


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