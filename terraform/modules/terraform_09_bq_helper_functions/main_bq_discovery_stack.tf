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

########################################################################################################################
#                                            Locals & Data
########################################################################################################################

locals {
  apis_list = [
    "cloudfunctions.googleapis.com",
    "datastore.googleapis.com",
    "firestore.googleapis.com",
  ]
}

########################################################################################################################
#                                            APIs
########################################################################################################################

resource "google_project_service" "enable_apis" {
  count = length(local.apis_list)
  project = var.application_project
  service = local.apis_list[count.index]

  disable_on_destroy = false
  disable_dependent_services = true
}

########################################################################################################################
#                                            Datastore
########################################################################################################################

// datastore is used as a cache layer by the function
resource "google_firestore_database" "datastore_mode_database" {
  project                           = var.application_project
  name                              = var.datastore_database_name
  location_id                       = var.compute_region
  type                              = "DATASTORE_MODE"
  concurrency_mode                  = "OPTIMISTIC"
  app_engine_integration_mode       = "DISABLED"
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_DISABLED"
  delete_protection_state           = "DELETE_PROTECTION_DISABLED"
  deletion_policy                   = "DELETE"
}

########################################################################################################################
#                                            Helper Functions
########################################################################################################################

# Helper functions for data analysis
module "bq-remote-func-get-table-policy-tags" {
  source                         = "./modules/bq-remote-function"
  function_name                  = var.bq_remote_func_get_policy_tags_name
  cloud_function_src_dir         = "../../../helpers/bq-remote-functions/get-policy-tags"
  cloud_function_temp_dir        = "/tmp/get-policy-tags.zip"
  service_account_name           = var.sa_bq_remote_func_get_policy_tags
  function_entry_point           = "process_request"
  // add more env_variables using merge({key=value}, {key=value}, etc}
  env_variables                  = {"DATASTORE_CACHE_DB_NAME" = var.datastore_database_name}
  project                        = var.application_project
  publishing_project             = var.publishing_project
  compute_region                 = var.compute_region
  data_region                    = var.data_region
  bigquery_dataset_name          = var.bigquery_dataset_name
  deployment_procedure_path      = "modules/bq-remote-function/procedures/deploy_get_policy_tags_remote_func.tpl"
  cloud_functions_sa_extra_roles = ["roles/datastore.user"]
}

########################################################################################################################
#                                            IAM Folder Level
########################################################################################################################

# Cloud Function remote_get_table_policy_tags needs to read tables policy tags (metadata)
resource "google_folder_iam_member" "data_folder_iam_remote_func_bq_metadata_viewer" {
  count = length(var.dlp_bq_configurations_folders)
  folder = "folders/${var.dlp_bq_configurations_folders[count.index]}"
  role = "roles/bigquery.metadataViewer"
  member = "serviceAccount:${module.bq-remote-func-get-table-policy-tags.cloud_function_sa_email}"
}

# Cloud Function remote_get_table_policy_tags needs to read policy tags and their metadata
resource "google_folder_iam_member" "data_folder_iam_remote_func_datacatalog_viewer" {
  count = length(var.dlp_bq_configurations_folders)
  folder = "folders/${var.dlp_bq_configurations_folders[count.index]}"
  role = "roles/datacatalog.viewer"
  member = "serviceAccount:${module.bq-remote-func-get-table-policy-tags.cloud_function_sa_email}"
}

########################################################################################################################
#                                            Stack-Specific Output
########################################################################################################################

output "sa_bq_remote_func_get_policy_tags_email" {
  value = module.bq-remote-func-get-table-policy-tags.cloud_function_sa_email
}