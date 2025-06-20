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

### DLP for GCS modules

module "gcs-discovery-stack" {
  source = "./stacks/gcs_discovery_stack"

  // deploy this stack once only when instructed
  count = var.deploy_gcs_annotations_stack? 1: 0

  image_name                                     = var.services_container_image_name
  java_class_path_gcs_dispatcher_service         = var.java_class_path_gcs_dispatcher_service
  java_class_path_gcs_tagger_service             = var.java_class_path_gcs_tagger_service

  dlp_notifications_topic_name                   = var.dlp_for_gcs_pubsub_topic_name
  logging_dataset_name                           = google_bigquery_dataset.logging_dataset.dataset_id
  dlp_dataset_name                               = var.dlp_dataset_name
  compute_region                                 = var.compute_region
  gar_docker_repo_name                           = var.gar_docker_repo_name
  project                                        = var.application_project
  publishing_project                             = var.publishing_project
  tagger_service_timeout_seconds                 = var.tagger_service_timeout_seconds
  info_type_map                                  = local.info_types_map
  is_dry_run_labels                              = var.is_dry_run_labels
  tagger_subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  tagger_subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
  dlp_gcs_bq_results_table_name                  = var.dlp_gcs_bq_results_table_name
  tagger_gcs_pubsub_sub                          = var.tagger_gcs_pubsub_sub
  tagger_gcs_pubsub_topic                        = var.tagger_gcs_pubsub_topic
  tagger_gcs_service_name                        = var.tagger_gcs_service_name
  gcs_existing_labels_regex                      = var.existing_labels_regex
  retain_dlp_tagger_pubsub_messages              = var.retain_dlp_tagger_pubsub_messages
  workflows_gcs_description                      = var.workflows_gcs_description
  workflows_gcs_name                             = var.workflows_gcs_name
  bq_view_run_summary                            = google_bigquery_table.view_run_summary.table_id
  logging_table_name                             = google_bigquery_table.logging_table_cloud_run.table_id
  terraform_data_deletion_protection             = var.terraform_data_deletion_protection
  info_type_map_file_path                        = "gs://${google_storage_bucket.gcs_solution_resources.name}/${google_storage_bucket_object.info_type_map_file.name}"

  # service accounts
  application_service_account_name = var.application_service_account_name
  tagger_gcs_service_account_name  = var.tagger_gcs_service_account_name

  # Dispatcher Cloud Batch scalability settings
  dispatcher_cloud_batch_cpu_millis               = var.dispatcher_cloud_batch_cpu_millis
  dispatcher_cloud_batch_memory_mib               = var.dispatcher_cloud_batch_memory_mib
  dispatcher_cloud_batch_max_run_duration_seconds = var.dispatcher_cloud_batch_max_run_duration_seconds
  dispatcher_pubsub_client_config                 = var.dispatcher_pubsub_client_config

  # Tagger Cloud Run scalability settings
  tagger_service_max_containers             = var.tagger_gcs_service_max_containers
  tagger_service_max_cpu                    = var.tagger_gcs_service_max_cpu
  tagger_service_max_memory                 = var.tagger_gcs_service_max_memory
  tagger_service_max_requests_per_container = var.tagger_gcs_service_max_requests_per_container

  depends_on = [
    google_bigquery_table.logging_table_cloud_run
  ]
}
