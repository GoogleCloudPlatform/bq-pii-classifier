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
#                                            PubSub
########################################################################################################################

resource "google_pubsub_topic" "dlp_gcs_topic" {
  project = var.application_project
  name    = var.dlp_for_gcs_pubsub_topic_name
}

resource "google_pubsub_topic" "dlp_gcs_errors_topic" {
  project = var.application_project
  name    = var.dlp_for_gcs_errors_pubsub_topic_name
}

resource "google_pubsub_subscription" "dlp_gcs_errors_subscription" {
  name  = var.dlp_for_gcs_errors_pubsub_subscription_name
  topic = google_pubsub_topic.dlp_gcs_errors_topic.id

  bigquery_config {
    table = "${google_bigquery_dataset.results_dataset.project}.${google_bigquery_dataset.results_dataset.dataset_id}.${google_bigquery_table.dlp_errors_table.table_id}"
  }

  depends_on = [google_bigquery_dataset_iam_member.results_dataset_pubsub_writer]
}

########################################################################################################################
#                                            DLP Configs
########################################################################################################################

module "gcs_dlp_configs" {
  source = "./modules/dlp_gcs_discovery_config"

  count = length(var.dlp_gcs_discovery_configurations)

  dlp_agent_project_id                             = var.dlp_gcs_discovery_configurations[count.index].parent_type == "organization"? var.application_project : var.dlp_gcs_discovery_configurations[count.index].parent_id

  dlp_gcs_scan_parent_type                        = var.dlp_gcs_discovery_configurations[count.index].parent_type
  dlp_gcs_scan_parent_id                          = var.dlp_gcs_discovery_configurations[count.index].parent_id
  dlp_gcs_scan_target_entity_id                   = var.dlp_gcs_discovery_configurations[count.index].target_id
  dlp_gcs_bucket_name_regex                       = var.dlp_gcs_discovery_configurations[count.index].bucket_name_regex
  dlp_gcs_project_id_regex                        = var.dlp_gcs_discovery_configurations[count.index].project_id_regex
  dlp_gcs_apply_tags                              = var.dlp_gcs_discovery_configurations[count.index].apply_tags
  dlp_gcs_create_configuration_in_paused_state    = var.dlp_gcs_discovery_configurations[count.index].create_configuration_in_paused_state
  dlp_gcs_reprofile_frequency                     = var.dlp_gcs_discovery_configurations[count.index].reprofile_frequency
  dlp_gcs_reprofile_on_inspection_template_update = var.dlp_gcs_discovery_configurations[count.index].reprofile_frequency_on_inspection_template_update
  dlp_gcs_included_bucket_attributes              = var.dlp_gcs_discovery_configurations[count.index].included_bucket_attributes
  dlp_gcs_included_object_attributes              = var.dlp_gcs_discovery_configurations[count.index].included_object_attributes

  bq_results_dataset                = google_bigquery_dataset.results_dataset.dataset_id
  data_region                       = var.data_region
  dlp_gcs_bq_results_table_name     = var.dlp_gcs_results_table_name
  dlp_inspection_templates_ids_list = local.dlp_inspection_templates_ids_list
  dlp_tag_high_sensitivity_id       = var.dlp_tag_high_sensitivity_value_namespaced_name
  dlp_tag_moderate_sensitivity_id   = var.dlp_tag_moderate_sensitivity_value_namespaced_name
  dlp_tag_low_sensitivity_id        = var.dlp_tag_low_sensitivity_value_namespaced_name
  pubsub_tagger_topic_id            = google_pubsub_topic.dlp_gcs_topic.id
  pubsub_errors_topic_id            = google_pubsub_topic.dlp_gcs_errors_topic.id
  publishing_project                = var.publishing_project
}