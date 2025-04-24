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

variable "gar_docker_repo_name" {
  type = string
}

variable "dlp_inspection_templates_ids_list" {
  type = list(string)
}

variable "bq_results_dataset" {
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
  type = bool
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

variable "image_name" {
  type = string
}

## ### Stack specific variables - Default value variables from main

variable "dlp_gcs_bq_results_table_name" {
  type        = string
  description = "Name of the table that DLP will create to save the findings. This will be created in the solution dataset"
}

##### Tagging Dispatcher Service ######

variable "sa_tagging_dispatcher_gcs" {
  type = string
}

##### GCS Tagger Service ######

variable "tagger_gcs_service_name" {
  type = string
}

variable "tagger_gcs_pubsub_topic" {
  type = string
}

variable "tagger_gcs_pubsub_sub" {
  type = string
}

variable "gcs_existing_labels_regex" {
  type = string
}

variable "retain_dlp_tagger_pubsub_messages" {
  type = bool
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

variable "info_type_map_file_path" {
  type = string
}

variable "dlp_gcs_discovery_configurations" {
  type = list(object({
    # Folder to be scanned
    folder_id = string

    # Regex for project ids to be covered by the DLP scan of GCS buckets. For organization-level configuration, if unset, will match all projects
    project_id_regex = string

    # Regex to test the bucket name against during the DLP scan. If empty, all buckets match
    bucket_name_regex = string

    # When set to true, DLP discovery service will attach pre-existing data sensitivity levels tags to buckets
    apply_tags = bool

    # When set to true, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to false, the discovery scan will start running upon creation
    create_configuration_in_paused_state = bool

    # If you set this field, profiles are refreshed at this frequency regardless of whether the underlying data have changes. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY
    reprofile_frequency = string

    # How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
    reprofile_frequency_on_inspection_template_update = string

    # Only objects with the specified attributes will be scanned. Defaults to [ALL_SUPPORTED_BUCKETS] if unset. Each value may be one of: ALL_SUPPORTED_BUCKETS, AUTOCLASS_DISABLED, AUTOCLASS_ENABLED.
    included_bucket_attributes = list(string)

    # "Only objects with the specified attributes will be scanned. If an object has one of the specified attributes but is inside an excluded bucket, it will not be scanned. Defaults to [ALL_SUPPORTED_OBJECTS]. A profile will be created even if no objects match the included_object_attributes. Each value may be one of: ALL_SUPPORTED_OBJECTS, STANDARD, NEARLINE, COLDLINE, ARCHIVE, REGIONAL, MULTI_REGIONAL, DURABLE_REDUCED_AVAILABILITY."
    included_object_attributes = list(string)
  }))
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
    pubsub_flow_control_max_outstanding_request_bytes = number    # 10 MiB (10 * 1024 * 1024)
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

variable "tagger_gcs_service_account_name" {
  type = string
}
