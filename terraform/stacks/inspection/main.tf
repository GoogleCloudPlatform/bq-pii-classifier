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

  timestamp = formatdate("YYMMDDhhmmss", timestamp())
  dlp_region = var.data_region == "eu" ? "europe" : var.data_region
}


module "inspection_cloud_scheduler" {
  source = "../../modules/cloud-scheduler"
  project = var.project
  region = var.compute_region
  scheduler_name = "${var.scheduler_name}-${var.env}"


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
  service_name = "${var.dispatcher_service_name}-${var.env}"
  service_account_email = google_service_account.sa_inspection_dispatcher.email
  invoker_service_account_email = google_service_account.sa_inspection_dispatcher_tasks.email
  environment_variables =  [
    {
      name = "BQ_VIEW_FIELDS_FINDINGS_SPEC",
      value = var.bq_view_dlp_fields_findings,
    },
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
    ]
}

module "cloud-run-inspector" {
  source = "../../modules/cloud-run"
  project = var.project
  region = var.compute_region
  service_image = var.inspector_service_image
  service_name = "${var.inspector_service_name}-${var.env}"
  service_account_email = google_service_account.sa_inspector.email
  invoker_service_account_email = google_service_account.sa_inspector_tasks.email

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
      value = var.dlp_inspection_template_id,
    },
    {
      name = "MIN_LIKELIHOOD",
      value = "LIKELY",
    },
    {
      name = "MAX_FINDINGS_PER_ITEM",
      value = "100",
    },
    {
      name = "SAMPLING_METHOD",
      value = "2",
    },
    {
      name = "DLP_NOTIFICATION_TOPIC",
      value = module.pubsub-listener.topic-id,
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

  ]
}

module "cloud-run-listener" {
  source = "../../modules/cloud-run"
  project = var.project
  region = var.compute_region
  service_image = var.listener_service_image
  service_name = "${var.listener_service_name}-${var.env}"
  service_account_email = google_service_account.sa_listener.email
  invoker_service_account_email = google_service_account.sa_listener_tasks.email

  environment_variables =  [
    {
      name = "REGION_ID",
      value = var.compute_region,
    },
    {
      name = "PROJECT_ID",
      value = var.project,
    },
    {
      name = "TAGGER_TOPIC_ID",
      value = var.tagger_topic,
    },
  ]
}


// PubSub

module "pubsub-inspection-dispatcher" {
  source = "../../modules/pubsub"
  project = var.project
  subscription_endpoint = module.cloud-run-inspection-dispatcher.service_endpoint
  subscription_name = "${var.dispatcher_pubsub_sub}_${var.env}"
  subscription_service_account = google_service_account.sa_inspection_dispatcher_tasks.email
  topic = "${var.dispatcher_pubsub_topic}_${var.env}"
  topic_publisher_sa_email = var.cloud_scheduler_account
}

module "pubsub-inspector" {
  source = "../../modules/pubsub"
  project = var.project
  subscription_endpoint = module.cloud-run-inspector.service_endpoint
  subscription_name = "${var.inspector_pubsub_sub}_${var.env}"
  subscription_service_account = google_service_account.sa_inspector_tasks.email
  topic = "${var.inspector_pubsub_topic}_${var.env}"
  topic_publisher_sa_email = google_service_account.sa_inspection_dispatcher.email
}

module "pubsub-listener" {
  source = "../../modules/pubsub"
  project = var.project
  subscription_endpoint = module.cloud-run-listener.service_endpoint
  subscription_name = "${var.listener_pubsub_sub}_${var.env}"
  subscription_service_account = google_service_account.sa_listener_tasks.email
  topic = "${var.listener_pubsub_topic}_${var.env}"
  // DLP is publishing to the listener topic and not Inspector
  topic_publisher_sa_email = var.dlp_service_account
}







