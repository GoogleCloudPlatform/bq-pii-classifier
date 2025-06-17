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

variable "project" {
  type = string
}

variable "publishing_project" {
  type = string
}

variable "data_region" {
  type = string
}

variable "dlp_inspection_templates_ids_list" {
  type = list(string)
}

variable "dlp_gcs_scan_org_id" {
  type        = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
}

variable "dlp_gcs_scan_folder_id" {
  type        = number
  description = "GCP folder ID that will be scanned by DLP discovery service for GCS"
}

variable "dlp_gcs_included_object_attributes" {
  type        = list(string)
  description = "Only objects with the specified attributes will be scanned. If an object has one of the specified attributes but is inside an excluded bucket, it will not be scanned. Defaults to [ALL_SUPPORTED_OBJECTS]. A profile will be created even if no objects match the included_object_attributes. Each value may be one of: ALL_SUPPORTED_OBJECTS, STANDARD, NEARLINE, COLDLINE, ARCHIVE, REGIONAL, MULTI_REGIONAL, DURABLE_REDUCED_AVAILABILITY."
}

variable "dlp_gcs_included_bucket_attributes" {
  type        = list(string)
  description = "Only objects with the specified attributes will be scanned. Defaults to [ALL_SUPPORTED_BUCKETS] if unset. Each value may be one of: ALL_SUPPORTED_BUCKETS, AUTOCLASS_DISABLED, AUTOCLASS_ENABLED."
}

variable "dlp_gcs_reprofile_on_inspection_template_update" {
  type        = string
  description = "How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
}

variable "dlp_gcs_reprofile_frequency" {
  type        = string
  description = "If you set this field, profiles are refreshed at this frequency regardless of whether the underlying data have changes. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY"
}

variable "dlp_gcs_create_configuration_in_paused_state" {
  type        = bool
  description = "When set to true, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to false, the discovery scan will start running upon creation"
}

variable "dlp_gcs_project_id_regex" {
  type        = string
  description = "Regex for project ids to be covered by the DLP scan of GCS buckets. For organization-level configuration, if unset, will match all projects"
}

variable "dlp_gcs_bucket_name_regex" {
  type        = string
  description = "Regex to test the bucket name against during the DLP scan. If empty, all buckets match"
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

variable "dlp_gcs_apply_tags" {
  type = bool
}

variable "bq_results_dataset" {
  type = string
}

variable "dlp_gcs_bq_results_table_name" {
  type = string
}

variable "pubsub_tagger_topic_id" {
  type = string
}