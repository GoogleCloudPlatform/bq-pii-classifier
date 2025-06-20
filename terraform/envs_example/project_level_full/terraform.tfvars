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

terraform_service_account_email ="terraform@<PROJECT_ID>.iam.gserviceaccount.com"

application_project = "<PROJECT_ID>"
publishing_project = "PUBLISHING_PROJECT_ID"
compute_region = "us-central1"
data_region    = "us"
source_data_regions = ["europe-west3", "eu", "us"]
terraform_data_deletion_protection = false # set to `true` for prod environments
services_container_image_name = "annotation-services:latest"


### DLP Module variables

deploy_dlp_inspection_template_to_global_region = true

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

custom_info_types_dictionaries = [
  {
    name       = "CUSTOM_PAYMENT_METHOD"
    likelihood = "LIKELY"
    dictionary = ["Debit Card", "Credit Card"]
  }
]

custom_info_types_regex = [
  {
    name       = "CUSTOM_EMAIL"
    likelihood = "LIKELY"
    regex      = "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}"
  }
]

# BigQuery discovery
dlp_bq_discovery_configurations = [
  {
    parent_type                                       = "project"
    parent_id                                         = "DATA_PROJECT_ID_#1"
    target_id                                         = "DATA_PROJECT_ID_#1"

    project_id_regex                                  = ".*" # must be .* or same as parent_id
    dataset_regex                                     = "^only-this-dataset$"
    table_regex                                       = ".*" # all tables
    apply_tags                                        = true
    create_configuration_in_paused_state              = false
    table_types = ["BIG_QUERY_TABLE_TYPE_TABLE", "BIG_QUERY_TABLE_TYPE_EXTERNAL_BIG_LAKE"]
    reprofile_frequency_on_table_schema_update        = "UPDATE_FREQUENCY_NEVER"
    reprofile_frequency_on_table_data_update          = "UPDATE_FREQUENCY_NEVER"
    reprofile_frequency_on_inspection_template_update = "UPDATE_FREQUENCY_NEVER"
    reprofile_types_on_schema_update = ["SCHEMA_NEW_COLUMNS"]
    reprofile_types_on_table_data_update = ["TABLE_MODIFIED_TIMESTAMP"]
  },
  {
    parent_type                                       = "project"
    parent_id                                         = "DATA_PROJECT_ID_#2"
    target_id                                         = "DATA_PROJECT_ID_#2"
    # all other fields are set to defaults
  }
]

# Cloud Storage discovery
dlp_gcs_discovery_configurations = [
  {
    parent_type                                       = "project"
    parent_id                                         = "DATA_PROJECT_ID_#1"
    target_id                                         = "DATA_PROJECT_ID_#1"

    project_id_regex                                  = ".*" # must be .* or same as parent_id
    bucket_name_regex                                 = ".*"
    apply_tags                                        = true
    create_configuration_in_paused_state              = true
    reprofile_frequency                               = "UPDATE_FREQUENCY_DAILY"
    reprofile_frequency_on_inspection_template_update = "UPDATE_FREQUENCY_DAILY"
    included_bucket_attributes = ["ALL_SUPPORTED_BUCKETS"]
    included_object_attributes = ["ALL_SUPPORTED_OBJECTS"]
  },
  {
    parent_type                                       = "project"
    parent_id                                         = "DATA_PROJECT_ID_#2"
    target_id                                         = "DATA_PROJECT_ID_#2"
    # all other fields are set to defaults
  }
]

### Tags Module variables

# these tags will be created in the application project
dlp_tag_sensitivity_level_key_name = "dlp_sensitivity_level"
ignore_dlp_sensitivity_key_name    = "bypass_dlp_sensitivity_level"

### Annotations Module variables
classification_taxonomy = [
  {
    info_type                                                                   = "EMAIL_ADDRESS",
    info_type_category                                                          = "Standard",
    policy_tag                                                                  = "email_address",
    classification                                                              = "PII",
    labels = [{ key = "contains_pii", value = "yes" }], taxonomy_number = 1,
  },
  {
    info_type                                                                   = "PHONE_NUMBER",
    info_type_category                                                          = "Standard",
    policy_tag                                                                  = "phone_number",
    classification                                                              = "PII",
    labels = [{ key = "contains_pii", value = "yes" }], taxonomy_number = 1,
  },
  {
    info_type       = "STREET_ADDRESS",
    info_type_category = "Standard",
    policy_tag = "street_address",
    classification  = "Location",
    labels = [{ key = "contains_location", value = "yes" }, { key = "contains_pii", value = "yes" }],
    taxonomy_number = 1,
  },
  {
    info_type                                                                   = "PERSON_NAME",
    info_type_category                                                          = "Standard",
    policy_tag                                                                  = "person_name",
    classification                                                              = "PII",
    labels = [{ key = "contains_pii", value = "yes" }], taxonomy_number = 1,
  },
]