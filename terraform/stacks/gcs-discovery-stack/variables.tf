## REQUIRED VARIABLES

### Variables passed from main

variable "project" {
  type = string
}

variable "compute_region" {
  type = string
}

variable "data_region" {
  type = string
}

variable "source_data_regions" {
  type = set(string)
}

variable "gar_docker_repo_name" {
  type = string
}

variable "dlp_inspection_templates_ids_list" {
  type = list(string)
}

variable "bq_results_dataset" {
  type = string
}

variable "dispatcher_service_timeout_seconds" {
  type = number
}

variable "dispatcher_subscription_ack_deadline_seconds" {
  type = number
}

variable "dispatcher_subscription_message_retention_duration" {
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

variable "gcs_flags_bucket_name" {
  type = string
}

variable "is_dry_run_labels" {
  type = string
}

variable "info_type_map" {
  // map( info_type_name: str, info_type_meta_data: object) where info_type_meta_data is an object( classification:str, labels: list) and labels is a list of key-value pairs represented as a map
  type = map(object({classification = string, labels = list(map(string))}))
}

variable "dlp_service_account_email" {
  type = string
}



### Stack specific variables - required by user

variable "dlp_gcs_scan_org_id" {
  type        = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
}

variable "dlp_gcs_scan_folder_id" {
  type        = number
  description = "GCP folder ID that will be scanned by DLP discovery service for GCS"
}

variable "image_name" {
  type = string
}

## ### Stack specific variables - Default value variables from main

variable "dlp_gcs_project_id_regex" {
  type        = string
  description = "Regex for project ids to be covered by the DLP scan of GCS buckets. For organization-level configuration, if unset, will match all projects"
}

variable "dlp_gcs_bucket_name_regex" {
  type        = string
  description = "Regex to test the bucket name against during the DLP scan. If empty, all buckets match"
}

variable "dlp_gcs_bq_results_table_name" {
  type        = string
  description = "Name of the table that DLP will create to save the findings. This will be created in the solution dataset"
}

variable "dlp_gcs_included_object_attributes" {
  type = list(string)
  description = "Only objects with the specified attributes will be scanned. If an object has one of the specified attributes but is inside an excluded bucket, it will not be scanned. Defaults to [ALL_SUPPORTED_OBJECTS]. A profile will be created even if no objects match the included_object_attributes. Each value may be one of: ALL_SUPPORTED_OBJECTS, STANDARD, NEARLINE, COLDLINE, ARCHIVE, REGIONAL, MULTI_REGIONAL, DURABLE_REDUCED_AVAILABILITY."
}

variable "dlp_gcs_included_bucket_attributes" {
  type = list(string)
  description = "Only objects with the specified attributes will be scanned. Defaults to [ALL_SUPPORTED_BUCKETS] if unset. Each value may be one of: ALL_SUPPORTED_BUCKETS, AUTOCLASS_DISABLED, AUTOCLASS_ENABLED."
}

variable "dlp_gcs_reprofile_on_inspection_template_update" {
  type = string
  description = "How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
}

variable "dlp_gcs_reprofile_on_data_change" {
  type = string
  description = "If you set this field, profiles are refreshed at this frequency regardless of whether the underlying tables have changes. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY"
}

variable "dlp_gcs_create_configuration_in_paused_state" {
  type = bool
  description = "When set to true, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to false, the discovery scan will start running upon creation"
}

##### Tagging Dispatcher Service ######

variable "sa_tagging_dispatcher_gcs" {
  type = string
}

variable "sa_tagging_dispatcher_gcs_tasks" {
  type = string
}

variable "tagging_dispatcher_gcs_service_name" {
  type = string
}

variable "tagging_dispatcher_gcs_pubsub_topic" {
  type = string
}

variable "tagging_dispatcher_gcs_pubsub_sub" {
  type = string
}



##### GCS Tagger Service ######

variable "sa_tagger_gcs" {
  type = string
}

variable "sa_tagger_gcs_tasks" {
  type = string
}

variable "tagger_gcs_service_name" {
  type = string
}

variable "tagger_gcs_pubsub_topic" {
  type = string
}

variable "tagger_gcs_pubsub_sub" {
  type = string
}

variable "bq_remote_func_get_buckets_metadata" {
  type = string
}

variable "sa_bq_remote_func_get_buckets_metadata" {
  type = string
}

variable "gcs_existing_labels_regex" {
  type = string
}

variable "dispatcher_service_max_cpu" {
  type = number
}

variable "dispatcher_service_max_memory" {
  type = string
}

variable "retain_dlp_tagger_pubsub_messages" {
  type = bool
}

variable "sa_workflows_gcs" {
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