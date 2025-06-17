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

module "bq-discovery-stack" {

  source = "./stacks/bq_discovery_stack"

  image_name                                     = var.services_container_image_name
  java_class_path_bq_dispatcher_service          = var.java_class_path_bq_dispatcher_service
  java_class_path_bq_tagger_service              = var.java_class_path_bq_tagger_service

  dlp_dataset_name                               = var.dlp_dataset_name
  dlp_notifications_topic_name                   = var.dlp_for_bq_pubsub_topic_name
  logging_dataset_name                           = google_bigquery_dataset.logging_dataset.dataset_id
  auto_dlp_results_table_name                    = var.auto_dlp_results_table_name
  bq_existing_labels_regex                       = var.existing_labels_regex
  bq_view_run_summary                            = google_bigquery_table.view_run_summary.table_id
  classification_taxonomy                        = var.classification_taxonomy
  compute_region                                 = var.compute_region
  data_catalog_taxonomy_activated_policy_types   = var.data_catalog_taxonomy_activated_policy_types
  default_domain_name                            = var.default_domain_name
  domain_mapping                                 = var.domain_mapping
  gar_docker_repo_name                           = var.gar_docker_repo_name
  iam_mapping                                    = var.iam_mapping
  is_dry_run_labels                              = var.is_dry_run_labels
  is_dry_run_tags                                = var.is_dry_run_tags
  logging_table_name                             = google_bigquery_table.logging_table_cloud_run.table_id
  project                                        = var.application_project
  publishing_project                             = var.publishing_project
  promote_dlp_other_matches                      = var.promote_dlp_other_matches
  retain_dlp_tagger_pubsub_messages              = var.retain_dlp_tagger_pubsub_messages
  tagger_bq_service_account_name                 = var.tagger_bq_service_account_name
  application_service_account_name               = var.application_service_account_name
  source_data_regions                            = var.source_data_regions
  tagger_pubsub_sub                              = var.tagger_pubsub_sub
  tagger_pubsub_topic                            = var.tagger_pubsub_topic
  tagger_service_name                            = var.tagger_service_name
  tagger_service_timeout_seconds                 = var.tagger_service_timeout_seconds
  tagger_subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  tagger_subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
  taxonomy_name_suffix                           = var.taxonomy_name_suffix
  terraform_data_deletion_protection             = var.terraform_data_deletion_protection
  workflows_bq_description                       = var.workflows_bq_description
  workflows_bq_name                              = var.workflows_bq_name
  resources_bucket_name                          = google_storage_bucket.gcs_solution_resources.name
  info_type_map_file_path                        = "gs://${google_storage_bucket.gcs_solution_resources.name}/${google_storage_bucket_object.info_type_map_file.name}"

  # Dispatcher Cloud Batch settings
  dispatcher_cloud_batch_cpu_millis               = var.dispatcher_cloud_batch_cpu_millis
  dispatcher_cloud_batch_memory_mib               = var.dispatcher_cloud_batch_memory_mib
  dispatcher_cloud_batch_max_run_duration_seconds = var.dispatcher_cloud_batch_max_run_duration_seconds
  dispatcher_pubsub_client_config                 = var.dispatcher_pubsub_client_config

  # Tagger Cloud Run scalability settings
  tagger_service_max_containers             = var.tagger_bq_service_max_containers
  tagger_service_max_cpu                    = var.tagger_bq_service_max_cpu
  tagger_service_max_memory                 = var.tagger_bq_service_max_memory
  tagger_service_max_requests_per_container = var.tagger_bq_service_max_requests_per_container

  depends_on = [
    google_bigquery_table.logging_table_cloud_run
  ]
}