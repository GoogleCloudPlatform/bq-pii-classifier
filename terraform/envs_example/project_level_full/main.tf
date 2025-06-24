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

module "apis" {
  source = "../../modules/terraform_00_apis"

  application_project = var.application_project
  publishing_project  = var.publishing_project

  // the union of all project-level configs, plus the application project (used for org-level configs)
  dlp_projects = distinct(concat(
    [for x in var.dlp_bq_discovery_configurations : x.target_id if x.parent_type == "project"],
    [for x in var.dlp_gcs_discovery_configurations : x.target_id if x.parent_type == "project"],
    [var.application_project]
  ))
}

// project-level tags for project-level dlp configs
module "project_tags" {
  source = "../../modules/terraform_03_tags"

  parent                             = "projects/${var.application_project}"

  dlp_tag_sensitivity_level_key_name = var.dlp_tag_sensitivity_level_key_name
  ignore_dlp_sensitivity_key_name    = var.ignore_dlp_sensitivity_key_name

  // only DLP service accounts (across all configs)  should be able to tag/untag resources with the DLP sensitivity tags (unless desired otherwise)
  dlp_tag_sensitivity_level_key_iam_tag_user_principles = [for x in var.dlp_service_accounts_emails: "serviceAccount:${x}"]
  // TODO: all users should be able to use the ignore/bypass tag. Set to an equivalent of "all users"
  ignore_dlp_sensitivity_key_iam_tag_user_principles = []
}

module "dlp" {
  source = "../../modules/terraform_04_dlp"

  application_project                = var.application_project
  publishing_project                 = var.publishing_project
  data_region                        = var.data_region
  source_data_regions                = var.source_data_regions
  terraform_data_deletion_protection = var.terraform_data_deletion_protection

  # tags for dlp
  # Note: dlp_gcs_discovery_configurations[*].apply_tags must be set to false if you want to skip setting these variables
  dlp_tag_high_sensitivity_value_namespaced_name     = module.project_tags.dlp_tag_high_sensitivity_namespaced_name
  dlp_tag_moderate_sensitivity_value_namespaced_name = module.project_tags.dlp_tag_moderate_sensitivity_namespaced_name
  dlp_tag_low_sensitivity_value_namespaced_name      = module.project_tags.dlp_tag_low_sensitivity_namespaced_name

  deploy_dlp_inspection_template_to_global_region = var.deploy_dlp_inspection_template_to_global_region

  built_in_info_types = var.built_in_info_types

  custom_info_types_dictionaries = var.custom_info_types_dictionaries

  custom_info_types_regex = var.custom_info_types_regex

  dlp_bq_discovery_configurations = var.dlp_bq_discovery_configurations

  dlp_gcs_discovery_configurations = var.dlp_gcs_discovery_configurations

  depends_on = [module.apis]
}

module "iam_on_host_project" {
  source = "../../modules/terraform_01_iam_host_project"

  application_project = var.application_project
  dlp_service_agents_emails = var.dlp_service_accounts_emails

  depends_on = [module.apis]
}

module "iam_on_publishing_project" {
  source = "../../modules/terraform_02_iam_publishing_project"

  application_project = var.application_project
  publishing_project  = var.publishing_project
  dlp_service_agents_emails = var.dlp_service_accounts_emails

  depends_on = [module.apis, module.iam_on_host_project]

}

module "annotations-solution" {
  source = "../../modules/terraform_05_annotations_infra"

  deploy_gcs_annotations_stack       = length(var.dlp_gcs_discovery_configurations) > 0
  deploy_bq_annotations_stack        = length(var.dlp_bq_discovery_configurations) > 0

  application_project                = var.application_project
  publishing_project                 = var.publishing_project
  data_region                        = var.data_region
  source_data_regions                = var.source_data_regions
  compute_region                     = var.compute_region
  terraform_data_deletion_protection = var.terraform_data_deletion_protection
  services_container_image_name      = var.services_container_image_name

  # Linked variables. One can also omit and use the defaults assuming that they are in-sync across modules
  dlp_dataset_name                 = module.dlp.dlp_results_dataset
  application_service_account_name = module.iam_on_host_project.sa_application_name
  tagger_bq_service_account_name   = module.iam_on_host_project.sa_tagger_bq_name
  tagger_gcs_service_account_name  = module.iam_on_host_project.sa_tagger_gcs_name
  dlp_for_bq_pubsub_topic_name     = module.dlp.dlp_bq_notifications_topic
  dlp_for_gcs_pubsub_topic_name    = module.dlp.dlp_gcs_notifications_topic
  default_domain_name              = "AnnotationsTestProjectLevel"

  classification_taxonomy = var.classification_taxonomy

  depends_on = [module.iam_on_host_project]
}

locals {
  all_dlp_projects = distinct(concat(module.dlp.dlp_gcs_projects,module.dlp.dlp_bq_projects))
}

module "iam_project_level" {
  source = "../../modules/terraform_08_iam_project_level"

  // grant permissions for the annotations service accounts to all projects where dlp is deployed
  count = length(local.all_dlp_projects)

  application_project = var.application_project
  dlp_project         = local.all_dlp_projects[count.index]

  depends_on = [module.iam_on_host_project]
}