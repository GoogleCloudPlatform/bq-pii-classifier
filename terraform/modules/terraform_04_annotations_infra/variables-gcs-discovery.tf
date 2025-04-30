## ### Stack specific variables - Default value variables

variable "dlp_gcs_bq_results_table_name" {
  type        = string
  description = "Name of the table that DLP will create to save the findings. This will be created in the solution dataset"
  default     = "dlp_discovery_services_gcs_results"
}

variable "workflows_gcs_name" {
  type = string
  default = "gcs_buckets_re_annotation_trigger"
}

variable "workflows_gcs_description" {
  type = string
  default = "Trigger (re)annotation process for Cloud Storage buckets based on DLP findings"
}

##### GCS Tagger Service ######

variable "tagger_gcs_service_account_name" {
  type = string
  default = "annotations-gcs"
}

variable "tagger_gcs_service_name" {
  type = string
  default = "tagger-gcs"
}

variable "tagger_gcs_pubsub_topic" {
  type = string
  default = "tagger_gcs_topic"
}

variable "tagger_gcs_pubsub_sub" {
  type = string
  default = "tagger_gcs_push_sub"
}

variable "gcs_existing_labels_regex" {
  type = string
  default = "(?!)" // Negative lookahead with an empty pattern to never match labels
  description = "A regex used to match existing bucket labels to be deleted and re-created based on the newest DLP findings and info type mapping"
}

# Tagger Scalability params

# Discovery Tagging:
#   GCS Tagger hits the DLP API (get file store profile), and Cloud Storage API (update bucket)
#   DLP API: 600 requests per minute
#   Storage API: NA
# Dispatcher Tagging:
#   Only hits the Storage API to add labels to buckets

variable "tagger_gcs_service_max_containers" {
  type = number
  default = 1
}

variable "tagger_gcs_service_max_requests_per_container" {
  type = number
  default = 80
}

variable "tagger_gcs_service_max_cpu" {
  type = number
  default = 2
}

variable "tagger_gcs_service_max_memory" {
  type = string
  default = "4Gi"
}

variable "dlp_for_gcs_pubsub_topic_name" {
  type = string
  default = "dlp_results_for_gcs_topic"
}