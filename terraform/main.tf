#   Copyright 2021 Google LLC
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

provider "google" {
  project                     = var.project
  region                      = var.compute_region
  impersonate_service_account = local.terraform_service_account_email
}

provider "google-beta" {
  project                     = var.project
  region                      = var.compute_region
  impersonate_service_account = local.terraform_service_account_email
}

data google_project "gcp_project" {
  project_id = var.project
}

locals {
  // Which SA should have access to the GCS flags bucket?
  // In all deployments, use these SAs
  common_gcs_admins = [
    "serviceAccount:${module.common-stack.sa_tagging_dispatcher_email}",
    "serviceAccount:${module.common-stack.sa_tagger_email}"
  ]
  // In Inspection Mode deployment (is_auto_dlp = false) use these:
  inspection_gcs_admins = var.is_auto_dlp_mode ? [] : [
    "serviceAccount:${module.inspection-stack[0].sa_inspection_dispatcher_email}",
    "serviceAccount:${module.inspection-stack[0].sa_inspector_email}"
  ]

  tagging_dispatcher_service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.tagging_dispatcher_service_image}"

  inspection_dispatcher_service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.inspection_dispatcher_service_image}"

  inspector_service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.inspector_service_image}"

  tagger_service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.tagger_service_image}"

  dlp_service_account_email =  "service-${data.google_project.gcp_project.number}@dlp-api.iam.gserviceaccount.com"

  cloud_scheduler_account_email = "service-${data.google_project.gcp_project.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"

  terraform_service_account_email = "${var.terraform_service_account}@${var.project}.iam.gserviceaccount.com"

  // create a list of distinct projects where data to be inspected resides
  data_projects = distinct(concat(
    flatten([for dataset in var.datasets_include_list : split(".", dataset)[0]]), // parse project_name from "project_name.dataset_name"
    var.projects_include_list // concat to the list of projects
  ))
}


module "gcs" {
  source                  = "./modules/gcs"
  gcs_flags_bucket_name   = "${var.project}-${var.gcs_flags_bucket_name}"
  project                 = var.project
  region                  = var.compute_region # because it's used by the cloud run services
  # both dispatchers should be admins. Add the inspection-dispatcher-sa only if it's being deployed
  gcs_flags_bucket_admins = var.is_auto_dlp_mode ? local.common_gcs_admins : concat(local.common_gcs_admins, local.inspection_gcs_admins)
  terraform_data_deletion_protection = var.terraform_data_deletion_protection
}

module "common-stack" {
  source                                       = "./stacks/common"
  classification_taxonomy                      = var.classification_taxonomy
  cloud_scheduler_account                      = local.cloud_scheduler_account_email
  cron_expression                              = var.tagging_cron_expression
  datasets_exclude_list                        = var.datasets_exclude_list
  datasets_include_list                        = var.datasets_include_list
  dispatcher_service_image                     = local.tagging_dispatcher_service_image_uri
  dlp_service_account                          = local.dlp_service_account_email
  domain_mapping                               = var.domain_mapping
  iam_mapping                                  = var.iam_mapping
  is_dry_run_tags                              = var.is_dry_run_tags
  is_dry_run_labels                            = var.is_dry_run_labels
  project                                      = var.project
  projects_include_list                        = var.projects_include_list
  compute_region                               = var.compute_region
  data_region                                  = var.data_region
  tables_exclude_list                          = var.tables_exclude_list
  tagger_service_image                         = local.tagger_service_image_uri
  bigquery_dataset_name                        = var.bigquery_dataset_name
  dispatcher_pubsub_sub                        = var.tagging_dispatcher_pubsub_sub
  dispatcher_pubsub_topic                      = var.tagging_dispatcher_pubsub_topic
  dispatcher_service_name                      = var.tagging_dispatcher_service_name
  log_sink_name                                = var.log_sink_name
  sa_tagger                                    = var.sa_tagger
  sa_tagger_tasks                              = var.sa_tagger_tasks
  scheduler_name                               = var.tagging_scheduler_name
  tagger_pubsub_sub                            = var.tagger_pubsub_sub
  tagger_pubsub_topic                          = var.tagger_pubsub_topic
  tagger_role                                  = var.tagger_role
  tagger_service_name                          = var.tagger_service_name
  is_auto_dlp_mode                             = var.is_auto_dlp_mode
  auto_dlp_results_table_name                  = var.auto_dlp_results_table_name
  standard_dlp_results_table_name              = var.standard_dlp_results_table_name
  sa_tagging_dispatcher                        = var.sa_tagging_dispatcher
  sa_tagging_dispatcher_tasks                  = var.sa_tagging_dispatcher_tasks
  data_catalog_taxonomy_activated_policy_types = var.data_catalog_taxonomy_activated_policy_types
  gcs_flags_bucket_name                        = module.gcs.create_gcs_flags_bucket_name

  dispatcher_service_timeout_seconds                 = var.dispatcher_service_timeout_seconds
  dispatcher_subscription_ack_deadline_seconds       = var.dispatcher_subscription_ack_deadline_seconds
  dispatcher_subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
  tagger_service_timeout_seconds                     = var.tagger_service_timeout_seconds
  tagger_subscription_ack_deadline_seconds           = var.tagger_subscription_ack_deadline_seconds
  tagger_subscription_message_retention_duration     = var.tagger_subscription_message_retention_duration
  promote_mixed_info_types                           = var.promote_mixed_info_types

  custom_info_types_dictionaries = var.custom_info_types_dictionaries
  custom_info_types_regex        = var.custom_info_types_regex
  source_data_regions            = var.source_data_regions
  taxonomy_name_suffix           = var.taxonomy_name_suffix
  terraform_data_deletion_protection = var.terraform_data_deletion_protection
}

module "inspection-stack" {
  source = "./stacks/inspection"
  // deploy the inspection stack only if the we are not in auto_dlp_mode
  count  = var.is_auto_dlp_mode ? 0 : 1

  bigquery_dataset_name           = module.common-stack.bq_results_dataset
  cloud_scheduler_account         = local.cloud_scheduler_account_email
  cron_expression                 = var.inspection_cron_expression
  datasets_exclude_list           = var.datasets_exclude_list
  datasets_include_list           = var.datasets_include_list
  dispatcher_service_image        = local.inspection_dispatcher_service_image_uri
  dlp_inspection_templates_ids    = module.common-stack.dlp_inspection_templates_ids
  inspector_service_image         = local.inspector_service_image_uri
  project                         = var.project
  projects_include_list           = var.projects_include_list
  compute_region                  = var.compute_region
  data_region                     = var.data_region
  source_data_regions             = var.source_data_regions
  table_scan_limits_json_config   = jsonencode(var.table_scan_limits_json_config)
  tables_exclude_list             = var.tables_exclude_list
  tagger_topic_id                 = module.common-stack.tagger_topic_id
  dispatcher_pubsub_sub           = var.inspection_dispatcher_pubsub_sub
  dispatcher_pubsub_topic         = var.inspection_dispatcher_pubsub_topic
  dispatcher_service_name         = var.inspection_dispatcher_service_name
  inspector_pubsub_sub            = var.inspector_pubsub_sub
  inspector_pubsub_topic          = var.inspector_pubsub_topic
  inspector_service_name          = var.inspector_service_name
  sa_inspector                    = var.sa_inspector
  sa_inspector_tasks              = var.sa_inspector_tasks
  scheduler_name                  = var.inspection_scheduler_name
  standard_dlp_results_table_name = var.standard_dlp_results_table_name
  sa_inspection_dispatcher        = var.sa_inspection_dispatcher
  sa_inspection_dispatcher_tasks  = var.sa_inspection_dispatcher_tasks
  dlp_max_findings_per_item       = var.dlp_max_findings_per_item
  dlp_min_likelihood              = var.dlp_min_likelihood
  dlp_sampling_method             = var.dlp_sampling_method
  gcs_flags_bucket_name           = module.gcs.create_gcs_flags_bucket_name

  dispatcher_service_timeout_seconds                 = var.dispatcher_service_timeout_seconds
  dispatcher_subscription_ack_deadline_seconds       = var.dispatcher_subscription_ack_deadline_seconds
  dispatcher_subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
  inspector_service_timeout_seconds                  = var.inspector_service_timeout_seconds
  inspector_subscription_ack_deadline_seconds        = var.inspector_subscription_ack_deadline_seconds
  inspector_subscription_message_retention_duration  = var.inspector_subscription_message_retention_duration
}

# Helper functions for data analysis
module "bq-remote-func-get-table-policy-tags" {
  source = "./modules/bq-remote-function"
  function_name = var.bq_remote_func_get_policy_tags_name
  cloud_function_src_dir  = "../helpers/bq-remote-functions/get-policy-tags"
  cloud_function_temp_dir = "/tmp/get-policy-tags.zip"
  service_account_name = var.sa_bq_remote_func_get_policy_tags
  function_entry_point = "process_request"
  env_variables = {}
  project = var.project
  compute_region = var.compute_region
  data_region = var.data_region
  bigquery_dataset_name = module.common-stack.bq_results_dataset
  deployment_procedure_path = "modules/bq-remote-function/procedures/deploy_get_policy_tags_remote_func.tpl"
  cloud_functions_sa_extra_roles = []

  depends_on             = [module.common-stack]
}

# Assign permissions for the service accounts used in this solution on the data projects when using standard mode.
# For this to run, the terraform service account must have permissions to set IAM policies on each data project. You can achieve this by running scripts/prepare_terraform_service_account_on_data_projects.sh "data-project-1" "data-project-2".
# If you can't grant the terraform account such access, this step can also be done via scripts/prepare_data_projects_for_standard_mode.sh by an authorized user
module "data_projects_permissions_in_standard_mode" {
  source = "./modules/data_project_permissions_in_standard_mode"
  // deploy this module only if we are in standard mode
  count  = var.is_auto_dlp_mode? 0: length(local.data_projects)

  target_project = local.data_projects[count.index]
  sa_bq_remote_func_get_policy_tags_email = module.bq-remote-func-get-table-policy-tags.cloud_function_sa_email
  sa_dlp_email = local.dlp_service_account_email
  sa_inspection_dispatcher_email = module.inspection-stack[0].sa_inspection_dispatcher_email
  sa_inspector_email = module.inspection-stack[0].sa_inspector_email
  sa_tagger_email = module.common-stack.sa_tagger_email
  sa_tagging_dispatcher_email = module.common-stack.sa_tagging_dispatcher_email
}




