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


locals {
  dlp_region = var.data_region == "eu" ? "europe" : var.data_region
}


module "inspection_cloud_scheduler" {
  source = "../../modules/cloud-scheduler"
  project = var.project
  region = var.compute_region
  scheduler_name = var.scheduler_name


  target_uri = module.pubsub-inspection-dispatcher.topic-id

  tables_include_list = var.tables_include_list
  datasets_include_list = var.datasets_include_list
  projects_include_list = var.projects_include_list
  datasets_exclude_list = var.datasets_exclude_list
  tables_exclude_list = var.tables_exclude_list
  cron_expression = var.cron_expression

}

module "cloud-run-inspection-dispatcher" {
  source = "../../modules/cloud-run"
  project = var.project
  region = var.compute_region
  service_image = var.dispatcher_service_image
  service_name = var.dispatcher_service_name
  service_account_email = google_service_account.sa_inspection_dispatcher.email
  invoker_service_account_email = google_service_account.sa_inspection_dispatcher_tasks.email
  # Dispatcher could take time to list large number of tables
  timeout_seconds = var.dispatcher_service_timeout_seconds
  # We don't need high conc for the entry point
  max_containers = 1
  # We need more than 1 CPU to help accelerate processing of large BigQuery Scan scope
  max_cpu = 2
  environment_variables =  [
    {
      name = "INSPECTION_TOPIC",
      value = module.pubsub-inspector.topic-name,
    },
    {
      name = "COMPUTE_REGION_ID",
      value = var.compute_region,
    },
    {
      name = "DATA_REGION_ID",
      value = var.data_region,
    },
    {
      name = "PROJECT_ID",
      value = var.project,
    },
    {
      name = "GCS_FLAGS_BUCKET",
      value = var.gcs_flags_bucket_name,
    },
    ]
}

module "cloud-run-inspector" {
  source = "../../modules/cloud-run"
  project = var.project
  region = var.compute_region
  service_image = var.inspector_service_image
  service_name = var.inspector_service_name
  service_account_email = google_service_account.sa_inspector.email
  invoker_service_account_email = google_service_account.sa_inspector_tasks.email
  timeout_seconds = var.inspector_service_timeout_seconds

  environment_variables =  [
    {
      name = "REGION_ID",
      value = local.dlp_region,
    },
    {
      name = "PROJECT_ID",
      value = var.project,
    },
    {
      name = "DLP_INSPECTION_TEMPLATE_ID",
      value = jsonencode(var.dlp_inspection_templates_ids),
    },
    {
      name = "MIN_LIKELIHOOD",
      value = var.dlp_min_likelihood,
    },
    {
      name = "MAX_FINDINGS_PER_ITEM",
      value = var.dlp_max_findings_per_item,
    },
    {
      name = "SAMPLING_METHOD",
      value = var.dlp_sampling_method,
    },
    {
      name = "DLP_NOTIFICATION_TOPIC",
      value = var.tagger_topic_id,
    },
    {
      name = "BQ_RESULTS_DATASET",
      value = var.bigquery_dataset_name,
    },
    {
      name = "BQ_RESULTS_TABLE",
      value = var.standard_dlp_results_table_name,
    },
    {
      name = "TABLE_SCAN_LIMITS_JSON_CONFIG",
      value = var.table_scan_limits_json_config,
    },
    {
      name = "GCS_FLAGS_BUCKET",
      value = var.gcs_flags_bucket_name,
    },
  ]
}


// PubSub

module "pubsub-inspection-dispatcher" {
  source = "../../modules/pubsub"
  project = var.project
  subscription_endpoint = module.cloud-run-inspection-dispatcher.service_endpoint
  subscription_name = var.dispatcher_pubsub_sub
  subscription_service_account = google_service_account.sa_inspection_dispatcher_tasks.email
  topic = var.dispatcher_pubsub_topic
  topic_publishers_sa_emails = [var.cloud_scheduler_account]
  # use a deadline large enough to process BQ listing for large scopes
  subscription_ack_deadline_seconds = var.dispatcher_subscription_ack_deadline_seconds
  # avoid resending dispatcher messages if things went wrong and the msg was NAK (e.g. timeout expired, app error, etc)
  # min value must be at equal to the ack_deadline_seconds
  subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
}

module "pubsub-inspector" {
  source = "../../modules/pubsub"
  project = var.project
  subscription_endpoint = module.cloud-run-inspector.service_endpoint
  subscription_name = var.inspector_pubsub_sub
  subscription_service_account = google_service_account.sa_inspector_tasks.email
  topic = var.inspector_pubsub_topic
  topic_publishers_sa_emails = [google_service_account.sa_inspection_dispatcher.email]
  subscription_ack_deadline_seconds = var.inspector_subscription_ack_deadline_seconds
  # How long to retain unacknowledged messages in the subscription's backlog, from the moment a message is published.
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions
  # However, retrying the inspector function with the same msg will lead to a non-retryable error due to dlp job name collision
  subscription_message_retention_duration = var.inspector_subscription_message_retention_duration

}







