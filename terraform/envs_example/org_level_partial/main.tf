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

data google_project "gcp_host_project" {
  project_id = var.application_project
}

/**
In this partial example we assume that all IAM-related modules are integrated in other external IAM environments.
Same for Org-level resources (i.e. Tags), we assume they are integrated under an external Org-level environment.
 */
module "dlp" {
  source = "../../modules/terraform_04_dlp"

  application_project                = var.application_project
  publishing_project                 = var.publishing_project
  data_region                        = var.data_region
  source_data_regions                = var.source_data_regions
  terraform_data_deletion_protection = var.terraform_data_deletion_protection

  # tags for dlp
  dlp_tag_high_sensitivity_value_namespaced_name     = "123/cloud-dlp-sensitivity-level/high"
  dlp_tag_moderate_sensitivity_value_namespaced_name = "123/cloud-dlp-sensitivity-level/moderate"
  dlp_tag_low_sensitivity_value_namespaced_name      = "123/cloud-dlp-sensitivity-level/low"

  deploy_dlp_inspection_template_to_global_region = var.deploy_dlp_inspection_template_to_global_region

  built_in_info_types = [
    {
      info_type = "EMAIL_ADDRESS"
    },
    {
      info_type = "PHONE_NUMBER"
    },
    {
      info_type = "STREET_ADDRESS"
    },
    {
      info_type = "PERSON_NAME"
    },
  ]

  custom_info_types_dictionaries = []

  custom_info_types_regex = []

  dlp_bq_discovery_configurations = []

  dlp_gcs_discovery_configurations = [
    {
      parent_type                                       = "organization"
      parent_id                                         = "ORG_ID"
      target_id                                         = "TARGET_FOLDER_ID"
      project_id_regex                                  = "^only-this-project$"
      bucket_name_regex                                 = ".*" # all buckets
      apply_tags                                        = true
      create_configuration_in_paused_state              = true
      reprofile_frequency                               = "UPDATE_FREQUENCY_DAILY"
      reprofile_frequency_on_inspection_template_update = "UPDATE_FREQUENCY_DAILY"
      included_bucket_attributes = ["ALL_SUPPORTED_BUCKETS"]
      included_object_attributes = ["ALL_SUPPORTED_OBJECTS"]
    }
  ]
}