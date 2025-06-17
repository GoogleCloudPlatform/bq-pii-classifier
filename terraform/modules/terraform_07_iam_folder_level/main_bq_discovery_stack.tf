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
#                                          DATA & LOCALS
########################################################################################################################

locals {
  tagger_bq_custom_role_resource_name = "organizations/${var.org_id}/roles/${var.tagger_bq_custom_role_id}"
}

########################################################################################################################
#                                          Modules
########################################################################################################################


// This module assigns roles and permissions to service accounts used in this solution on data FOLDER levels (and not the host project)
// The Terraform service account needs certain org/folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles on org and folder level
module "bq-discovery-stack-folder-permissions" {
  source = "./modules/bq-discovery-stack-folder-permissions"
  // deploy once per folder
  count = length(var.dlp_bq_configurations_folders)

  dlp_config_folder_id  = var.dlp_bq_configurations_folders[count.index]
  dlp_service_sa_email  = var.dlp_service_account_email
  sa_tagger_email       = var.tagger_bq_service_account_email
  tagger_custom_role_id = local.tagger_bq_custom_role_resource_name
}