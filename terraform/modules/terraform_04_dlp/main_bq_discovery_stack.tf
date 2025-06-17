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

resource "google_pubsub_topic" "dlp_bq_topic" {
  project = var.application_project
  name    = var.dlp_for_bq_pubsub_topic_name
}

########################################################################################################################
#                                            DLP Configs
########################################################################################################################

module "bq_dlp_configs" {
  source = "./modules/dlp_bq_discovery_config"

  count = length(var.dlp_bq_discovery_configurations)

  dlp_bq_scan_org_id = var.org_id

  dlp_bq_table_regex                                       = var.dlp_bq_discovery_configurations[count.index].table_regex
  dlp_bq_table_types                                       = var.dlp_bq_discovery_configurations[count.index].table_types
  dlp_bq_apply_tags                                        = var.dlp_bq_discovery_configurations[count.index].apply_tags
  dlp_bq_create_configuration_in_paused_state              = var.dlp_bq_discovery_configurations[count.index].create_configuration_in_paused_state
  dlp_bq_dataset_regex                                     = var.dlp_bq_discovery_configurations[count.index].dataset_regex
  dlp_bq_project_id_regex                                  = var.dlp_bq_discovery_configurations[count.index].project_id_regex
  dlp_bq_reprofile_on_inspection_template_update_frequency = var.dlp_bq_discovery_configurations[count.index].reprofile_frequency_on_inspection_template_update
  dlp_bq_reprofile_on_schema_update_types                  = var.dlp_bq_discovery_configurations[count.index].reprofile_types_on_schema_update
  dlp_bq_reprofile_on_table_data_update_frequency          = var.dlp_bq_discovery_configurations[count.index].reprofile_frequency_on_table_data_update
  dlp_bq_reprofile_on_table_data_update_types              = var.dlp_bq_discovery_configurations[count.index].reprofile_types_on_table_data_update
  dlp_bq_reprofile_on_table_schema_update_frequency        = var.dlp_bq_discovery_configurations[count.index].reprofile_frequency_on_table_schema_update
  dlp_bq_scan_folder_id                                    = var.dlp_bq_discovery_configurations[count.index].folder_id


  auto_dlp_results_table_name       = var.dlp_bq_results_table_name
  bigquery_dataset_name             = google_bigquery_dataset.results_dataset.dataset_id
  data_region                       = var.data_region
  dlp_inspection_templates_ids_list = local.dlp_inspection_templates_ids_list
  dlp_tag_high_sensitivity_id       = var.dlp_tag_high_sensitivity_value_namespaced_name
  dlp_tag_moderate_sensitivity_id   = var.dlp_tag_moderate_sensitivity_value_namespaced_name
  dlp_tag_low_sensitivity_id        = var.dlp_tag_low_sensitivity_value_namespaced_name
  project                           = var.application_project
  publishing_project                = var.publishing_project
  pubsub_tagger_topic_id            = google_pubsub_topic.dlp_bq_topic.id
}