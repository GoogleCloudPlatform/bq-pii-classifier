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

############## DLP DISCOVERY SERVICE ################

locals {
  dlp_regional_end_point = var.data_region == "eu" ? "europe" : var.data_region
}

resource "google_data_loss_prevention_discovery_config" "dlp_bq_org_folder" {

  location = local.dlp_regional_end_point

  parent = var.dlp_bq_scan_parent_type == "organization"? "organizations/${var.dlp_bq_scan_parent_id}/locations/${local.dlp_regional_end_point}" : "projects/${var.dlp_bq_scan_parent_id}/locations/${local.dlp_regional_end_point}"

  // conditionally set the org_config if we are deploying to an org node
  dynamic "org_config" {
    for_each = var.dlp_bq_scan_parent_type == "organization" ? [1] : []
    content {
      project_id = var.dlp_agent_project_id

      // The data to scan folder or project
      location {
        folder_id = var.dlp_bq_scan_target_entity_id
      }
    }
  }

  // inspection template(s) that will be used to inspect BQ tables
  inspect_templates = var.dlp_inspection_templates_ids_list

  // Enabled target with filter on specific projects/datasets/tables
  targets {
    big_query_target {

      filter {
        tables {
          include_regexes {
            patterns {
              project_id_regex = var.dlp_bq_project_id_regex
              dataset_id_regex = var.dlp_bq_dataset_regex
              table_id_regex   = var.dlp_bq_table_regex
            }
          }
        }
      }

      conditions {
        // Restrict discovery to specific table type Structure
        types {
          types = var.dlp_bq_table_types
        }
      }

      // How often and when to update profiles. New tables that match both the fiter and conditions are scanned as quickly as possible depending on system capacity (i.e. columns are added/updated/deleted)
      cadence {
        // Governs when to update data profiles when a schema is modified
        schema_modified_cadence {
          // The type of events to consider when deciding if the table's schema has been modified and should have the profile updated. Defaults to NEW_COLUMN. Each value may be one of: SCHEMA_NEW_COLUMNS, SCHEMA_REMOVED_COLUMNS
          types = var.dlp_bq_reprofile_on_schema_update_types
          // How frequently profiles may be updated when schemas are modified. Default to monthly Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY
          frequency = var.dlp_bq_reprofile_on_table_schema_update_frequency
        }
        // Governs when to update profile when a table is modified (i.e. rows are added/updated/deleted)
        table_modified_cadence {
          // The type of events to consider when deciding if the table has been modified and should have the profile updated. Defaults to MODIFIED_TIMESTAMP Each value may be one of: TABLE_MODIFIED_TIMESTAMP.
          types = var.dlp_bq_reprofile_on_table_data_update_types
          // How frequently data profiles can be updated when tables are modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
          frequency = var.dlp_bq_reprofile_on_table_data_update_frequency
        }
        // Governs when to update data profiles when the inspection rules defined by the InspectTemplate change. If not set, changing the template will not cause a data profile to update
        inspect_template_modified_cadence {
          // How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
          frequency = var.dlp_bq_reprofile_on_inspection_template_update_frequency
        }
      }
    }
  }

  // Target to cover all "other" unmatched resources. For all other matches than specified, do not profile.
  targets {
    big_query_target {
      filter {
        other_tables {}
      }
      disabled {}
    }
  }

  actions {
    export_data {
      profile_table {
        project_id = var.publishing_project
        dataset_id = var.bigquery_dataset_name
        table_id   = var.auto_dlp_results_table_name
      }
    }
  }

  actions {
    pub_sub_notification {
      topic = var.pubsub_tagger_topic_id
      // (Optional) The type of event that triggers a Pub/Sub. At most one PubSubNotification per EventType is permitted. Possible values are: NEW_PROFILE, CHANGED_PROFILE, SCORE_INCREASED, ERROR_CHANGED.
      event = "NEW_PROFILE"
      // (Optional) How much data to include in the pub/sub message. Possible values are: TABLE_PROFILE, RESOURCE_NAME. For GCS, only RESOURCE_NAME is allowed
      detail_of_message = "RESOURCE_NAME"
    }
  }

  actions {
    pub_sub_notification {
      topic = var.pubsub_tagger_topic_id
      // (Optional) The type of event that triggers a Pub/Sub. At most one PubSubNotification per EventType is permitted. Possible values are: NEW_PROFILE, CHANGED_PROFILE, SCORE_INCREASED, ERROR_CHANGED.
      event = "CHANGED_PROFILE"
      // (Optional) How much data to include in the pub/sub message. Possible values are: TABLE_PROFILE, RESOURCE_NAME. For GCS, only RESOURCE_NAME is allowed
      detail_of_message = "RESOURCE_NAME"
    }
  }

  actions {
    pub_sub_notification {
      topic = var.pubsub_errors_topic_id
      event = "ERROR_CHANGED"
      detail_of_message = "RESOURCE_NAME"
    }
  }

  dynamic actions {
    // conditionally set the tagging actions based based on boolean variable var.dlp_gcs_apply_tags
    for_each = var.dlp_bq_apply_tags ? [1] : []
    content {
      tag_resources {
        tag_conditions {
          tag {
            namespaced_value = var.dlp_tag_high_sensitivity_id
          }
          sensitivity_score {
            score = "SENSITIVITY_HIGH"
          }
        }
        tag_conditions {
          tag {
            namespaced_value = var.dlp_tag_moderate_sensitivity_id
          }
          sensitivity_score {
            score = "SENSITIVITY_MODERATE"
          }
        }
        tag_conditions {
          tag {
            namespaced_value = var.dlp_tag_low_sensitivity_id
          }
          sensitivity_score {
            score = "SENSITIVITY_LOW"
          }
        }
        # When to attach a tags to resources
        profile_generations_to_tag = ["PROFILE_GENERATION_NEW", "PROFILE_GENERATION_UPDATE"]

        # Whether applying a tag to a resource should lower the risk of the profile for that resource.
        # For example, in conjunction with an IAM deny policy, you can deny all principals a permission if
        # a tag value is present, mitigating the risk of the resource.
        # This also lowers the data risk of resources at the lower levels of the resource hierarchy.
        # For example, reducing the data risk of a table data profile also reduces the data risk of the constituent
        # column data profiles.
        lower_data_risk_to_low = true
      }
    }
  }

  // PAUSED | RUNNING
  status = var.dlp_bq_create_configuration_in_paused_state ? "PAUSED" : "RUNNING"
}