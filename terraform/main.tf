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
  project = var.project
  region = var.compute_region
  impersonate_service_account = var.terraform_service_account
}

provider "google-beta" {
  project = var.project
  region = var.compute_region
  impersonate_service_account = var.terraform_service_account
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
}


module "gcs" {
  source = "./modules/gcs"
  gcs_flags_bucket_name = "${var.project}-${var.gcs_flags_bucket_name}-${var.env}"
  project = var.project
  region = var.compute_region # because it's used by the cloud run services
  # both dispatchers should be admins. Add the inspection-dispatcher-sa only if it's being deployed
  gcs_flags_bucket_admins = var.is_auto_dlp_mode ? local.common_gcs_admins : concat(local.common_gcs_admins, local.inspection_gcs_admins)
}

module "common-stack" {
  source = "./stacks/common"
  classification_taxonomy = var.classification_taxonomy
  cloud_scheduler_account = var.cloud_scheduler_account
  cron_expression = var.tagging_cron_expression
  datasets_exclude_list = var.datasets_exclude_list
  datasets_include_list = var.datasets_include_list
  dispatcher_service_image = var.tagging_dispatcher_service_image
  dlp_service_account = var.dlp_service_account
  domain_mapping = var.domain_mapping
  env = var.env
  iam_mapping = var.iam_mapping
  is_dry_run = var.is_dry_run
  project = var.project
  projects_include_list = var.projects_include_list
  compute_region = var.compute_region
  data_region = var.data_region
  tables_exclude_list = var.tables_exclude_list
  tables_include_list = var.tables_include_list
  tagger_service_image = var.tagger_service_image
  bigquery_dataset_name = var.bigquery_dataset_name
  dispatcher_pubsub_sub = var.tagging_dispatcher_pubsub_sub
  dispatcher_pubsub_topic = var.tagging_dispatcher_pubsub_topic
  dispatcher_service_name = var.tagging_dispatcher_service_name
  log_sink_name = var.log_sink_name
  sa_tagger = var.sa_tagger
  sa_tagger_tasks = var.sa_tagger_tasks
  scheduler_name = var.tagging_scheduler_name
  tagger_pubsub_sub = var.tagger_pubsub_sub
  tagger_pubsub_topic = var.tagger_pubsub_topic
  tagger_role = var.tagger_role
  tagger_service_name = var.tagger_service_name
  is_auto_dlp_mode = var.is_auto_dlp_mode
  auto_dlp_results_table_name = var.auto_dlp_results_table_name
  standard_dlp_results_table_name = var.standard_dlp_results_table_name

  sa_inspection_dispatcher = var.sa_inspection_dispatcher
  sa_inspection_dispatcher_tasks = var.sa_inspection_dispatcher_tasks
  sa_inspector = var.sa_inspector
  sa_inspector_tasks = var.sa_inspector_tasks
  sa_listener = var.sa_listener
  sa_listener_tasks = var.sa_listener_tasks
  sa_tagging_dispatcher = var.sa_tagging_dispatcher
  sa_tagging_dispatcher_tasks = var.sa_tagging_dispatcher_tasks
  data_catalog_taxonomy_activated_policy_types = var.data_catalog_taxonomy_activated_policy_types
  gcs_flags_bucket_name = module.gcs.create_gcs_flags_bucket_name

  dispatcher_service_timeout_seconds = var.dispatcher_service_timeout_seconds
  dispatcher_subscription_ack_deadline_seconds = var.dispatcher_subscription_ack_deadline_seconds
  dispatcher_subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
  tagger_service_timeout_seconds = var.tagger_service_timeout_seconds
  tagger_subscription_ack_deadline_seconds = var.tagger_subscription_ack_deadline_seconds
  tagger_subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
  promote_mixed_info_types = var.promote_mixed_info_types
}

module "inspection-stack" {
  source = "./stacks/inspection"
  // deploy the inspection stack only if the we are not in auto_dlp_mode
  count = var.is_auto_dlp_mode ? 0 : 1

  bigquery_dataset_name = module.common-stack.bq_results_dataset
  cloud_scheduler_account = var.cloud_scheduler_account
  cron_expression = var.inspection_cron_expression
  datasets_exclude_list = var.datasets_exclude_list
  datasets_include_list = var.datasets_include_list
  dispatcher_service_image = var.inspection_dispatcher_service_image
  dlp_inspection_template_id = module.common-stack.dlp_inspection_template_id
  dlp_service_account = var.dlp_service_account
  env = var.env
  inspector_service_image = var.inspector_service_image
  listener_service_image = var.listener_service_image
  project = var.project
  projects_include_list = var.projects_include_list
  compute_region = var.compute_region
  data_region = var.data_region
  table_scan_limits_json_config = var.table_scan_limits_json_config
  tables_exclude_list = var.tables_exclude_list
  tables_include_list = var.tables_include_list
  tagger_topic = module.common-stack.tagger_topic_name
  dispatcher_pubsub_sub = var.inspection_dispatcher_pubsub_sub
  dispatcher_pubsub_topic = var.inspection_dispatcher_pubsub_topic
  dispatcher_service_name = var.inspection_dispatcher_service_name
  inspector_pubsub_sub = var.inspector_pubsub_sub
  inspector_pubsub_topic = var.inspector_pubsub_topic
  inspector_service_name = var.inspector_service_name
  listener_pubsub_sub = var.listener_pubsub_sub
  listener_pubsub_topic = var.listener_pubsub_topic
  listener_service_name = var.listener_service_name
  sa_inspector = var.sa_inspector
  sa_inspector_tasks = var.sa_inspector_tasks
  sa_listener = var.sa_listener
  sa_listener_tasks = var.sa_listener_tasks
  scheduler_name = var.inspection_scheduler_name
  standard_dlp_results_table_name = var.standard_dlp_results_table_name
  sa_inspection_dispatcher = var.sa_inspection_dispatcher
  sa_inspection_dispatcher_tasks = var.sa_inspection_dispatcher_tasks
  dlp_max_findings_per_item = var.dlp_max_findings_per_item
  dlp_min_likelihood = var.dlp_min_likelihood
  dlp_sampling_method = var.dlp_sampling_method
  gcs_flags_bucket_name = module.gcs.create_gcs_flags_bucket_name

  dispatcher_service_timeout_seconds = var.dispatcher_service_timeout_seconds
  dispatcher_subscription_ack_deadline_seconds = var.dispatcher_subscription_ack_deadline_seconds
  dispatcher_subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
  inspector_service_timeout_seconds = var.inspector_service_timeout_seconds
  inspector_subscription_ack_deadline_seconds = var.inspector_subscription_ack_deadline_seconds
  inspector_subscription_message_retention_duration = var.inspector_subscription_message_retention_duration
  listener_service_timeout_seconds = var.listener_service_timeout_seconds
  listener_subscription_ack_deadline_seconds = var.listener_subscription_ack_deadline_seconds
  listener_subscription_message_retention_duration = var.listener_subscription_message_retention_duration
}



