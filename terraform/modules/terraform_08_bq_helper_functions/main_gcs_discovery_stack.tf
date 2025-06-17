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
#                                            Helper Functions
########################################################################################################################

# Helper functions for data analysis and cost estimation
module "bq-remote-func-get-buckets-metadata" {
  source                    = "./modules/bq-remote-function"
  function_name             = var.bq_remote_func_get_buckets_metadata
  cloud_function_src_dir    = "../../../helpers/bq-remote-functions/get-buckets-metadata"
  cloud_function_temp_dir   = "/tmp/get-buckets-metadata.zip"
  service_account_name      = var.sa_bq_remote_func_get_buckets_metadata
  function_entry_point      = "process_request"
  env_variables = {}
  project                   = var.application_project
  publishing_project        = var.publishing_project
  compute_region            = var.compute_region
  data_region               = var.data_region
  bigquery_dataset_name     = var.bigquery_dataset_name
  deployment_procedure_path = "modules/bq-remote-function/procedures/deploy_get_buckets_metadata_remote_func.tpl"
  cloud_functions_sa_extra_roles = []
}

########################################################################################################################
#                                            IAM Org Level
########################################################################################################################

// Granular permissions needed by the get-buckets-metadata helper function (used for dlp cost estimation and reviewing labels)
resource "google_organization_iam_custom_role" "custom_role_get_buckets_metadata_func" {
  org_id      = var.org_id
  role_id     = "AnnotationsSolutionGetBucketsMetadataFunc"
  title       = "CR for the GCP Annotations solution to get buckets metadata via a BQ remote function"
  description = "Allows viewing of storage objects in specific buckets."

  permissions = [
    "storage.buckets.list", # to list buckets under a project
    "storage.buckets.get", # to get buckets metadata
    "monitoring.timeSeries.list", #  to get total bucket size from monitoring api (instead of listing down objects to get their size
    "resourcemanager.projects.list" # to list projects under folder
  ]

  stage = "GA"
}


########################################################################################################################
#                                            IAM Folder Level
########################################################################################################################

// grant permissions to the function on each data folder
resource "google_folder_iam_member" "iam_member_func_get_buckets_metadata_sa_custom_role" {
  count = length(var.dlp_gcs_configurations_folders)
  folder = "folders/${var.dlp_gcs_configurations_folders[count.index]}"
  role   = google_organization_iam_custom_role.custom_role_get_buckets_metadata_func.id
  member = "serviceAccount:${module.bq-remote-func-get-buckets-metadata.cloud_function_sa_email}"
}

########################################################################################################################
#                                            Stack-Specific Output
########################################################################################################################

output "func_get_buckets_metadata_sa_email" {
  value = module.bq-remote-func-get-buckets-metadata.cloud_function_sa_email
}

output "get_buckets_metadata_func_custom_role_id" {
  value = google_organization_iam_custom_role.custom_role_get_buckets_metadata_func.id
}