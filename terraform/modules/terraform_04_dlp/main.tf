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

#############################################################
#                                    Data & Locals
##############################################################

# deploy 1 dlp inspection template in each source data region
locals {
  dlp_regions = var.deploy_dlp_inspection_template_to_global_region ? concat(tolist(var.source_data_regions), [
    "global"
  ]) : var.source_data_regions

  created_dlp_inspection_templates = module.dlp_inspection_templates[*].created_inspection_templates

  dlp_inspection_templates_ids_list = flatten([for obj in local.created_dlp_inspection_templates : obj["ids"]])
}

data google_project "gcp_host_project" {
  project_id = var.application_project
}

#############################################################
#                                    Dlp Inspection Templates
##############################################################

module "dlp_inspection_templates" {
  count                          = length(local.dlp_regions)
  source                         = "./modules/dlp_inspection_template"
  project                        = var.application_project
  region                         = tolist(local.dlp_regions)[count.index]
  built_in_info_types            = var.built_in_info_types
  custom_info_types_dictionaries = var.custom_info_types_dictionaries
  custom_info_types_regex        = var.custom_info_types_regex
}

#############################################################
#                                    BigQuery
##############################################################

resource "google_bigquery_dataset" "results_dataset" {
  project     = var.publishing_project
  location    = var.data_region
  dataset_id  = var.bigquery_dlp_dataset_name
  description = "To store DLP results"

  delete_contents_on_destroy = ! var.terraform_data_deletion_protection
}

