
### Stack specific variables - required

variable "dlp_gcs_scan_org_id" {
  type        = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
}

variable "dlp_gcs_scan_folder_id" {
  type        = number
  description = "GCP folder ID that will be scanned by DLP discovery service for GCS"
}


variable "tagging_dispatcher_gcs_service_image" {
  type = string
}

variable "tagger_gcs_service_image" {
  type = string
}

## ### Stack specific variables - Default value variables

variable "dlp_gcs_project_id_regex" {
  type        = string
  description = "Regex for project ids to be covered by the DLP scan of GCS buckets. For organization-level configuration, if unset, will match all projects"
  default     = ".*"
}

variable "dlp_gcs_bucket_name_regex" {
  type        = string
  description = "Regex to test the bucket name against during the DLP scan. If empty, all buckets match"
  default     = ".*"
}

variable "dlp_gcs_bq_results_table_name" {
  type        = string
  description = "Name of the table that DLP will create to save the findings. This will be created in the solution dataset"
  default     = "dlp_discovery_services_gcs_results"
}

variable "dlp_gcs_included_object_attributes" {
  type = list(string)
  description = "Only objects with the specified attributes will be scanned. If an object has one of the specified attributes but is inside an excluded bucket, it will not be scanned. Defaults to [ALL_SUPPORTED_OBJECTS]. A profile will be created even if no objects match the included_object_attributes. Each value may be one of: ALL_SUPPORTED_OBJECTS, STANDARD, NEARLINE, COLDLINE, ARCHIVE, REGIONAL, MULTI_REGIONAL, DURABLE_REDUCED_AVAILABILITY."
  default = ["ALL_SUPPORTED_OBJECTS"]
}

variable "dlp_gcs_included_bucket_attributes" {
  type = list(string)
  description = "Only objects with the specified attributes will be scanned. Defaults to [ALL_SUPPORTED_BUCKETS] if unset. Each value may be one of: ALL_SUPPORTED_BUCKETS, AUTOCLASS_DISABLED, AUTOCLASS_ENABLED."
  default = ["ALL_SUPPORTED_BUCKETS"]
}

variable "dlp_gcs_reprofile_on_inspection_template_update" {
  type = string
  description = "How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
  default = "UPDATE_FREQUENCY_NEVER"
}

variable "dlp_gcs_reprofile_on_data_change" {
  type = string
  description = "If you set this field, profiles are refreshed at this frequency regardless of whether the underlying tables have changes. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY"
  default = "UPDATE_FREQUENCY_NEVER"
}

variable "dlp_gcs_create_configuration_in_paused_state" {
  type = bool
  description = "When set to true, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to false, the discovery scan will start running upon creation"
  default = true
}

##### Tagging Dispatcher Service ######

variable "sa_tagging_dispatcher_gcs" {
  type = string
  default = "tag-dispatcher-gcs"
}

variable "sa_tagging_dispatcher_gcs_tasks" {
  type = string
  default = "tag-dispatcher-gcs-tasks"
}

variable "tagging_dispatcher_gcs_service_name" {
  type = string
  default = "s1a-tagging-dispatcher-gcs"
}

variable "sa_workflows_gcs" {
  type = string
  default = "workflows-gcs"
}

variable "workflows_gcs_name" {
  type = string
  default = "gcs_buckets_re_annotation_trigger"
}

variable "workflows_gcs_description" {
  type = string
  default = "Trigger (re)annotation process for Cloud Storage buckets based on DLP findings"
}

variable "tagging_dispatcher_gcs_pubsub_topic" {
  type = string
  default = "tagging_dispatcher_gcs_topic"
}

variable "tagging_dispatcher_gcs_pubsub_sub" {
  type = string
  default = "tagging_dispatcher_gcs_push_sub"
}



##### GCS Tagger Service ######

variable "sa_tagger_gcs" {
  type = string
  default = "tagger-gcs"
}

variable "sa_tagger_gcs_tasks" {
  type = string
  default = "tagger-gcs-tasks"
}

variable "tagger_gcs_service_name" {
  type = string
  default = "s3-tagger-gcs"
}

variable "tagger_gcs_pubsub_topic" {
  type = string
  default = "tagger_gcs_topic"
}

variable "tagger_gcs_pubsub_sub" {
  type = string
  default = "tagger_gcs_push_sub"
}

variable "bq_remote_func_get_buckets_metadata" {
  type = string
  default = "get_buckets_metadata"
}

variable "sa_bq_remote_func_get_buckets_metadata" {
  type = string
  default = "sa-func-get-buckets-metadata"
}

variable "gcs_existing_labels_regex" {
  type = string
  default = "(?!)" // Negative lookahead with an empty pattern to never match labels
  description = "A regex used to match existing bucket labels to be deleted and re-created based on the newest DLP findings and info type mapping"
}
