locals {
  dlp_regional_end_point = var.data_region == "eu" ? "europe" : var.data_region
}


resource "google_data_loss_prevention_discovery_config" "dlp_bq_org_folder" {

  # deploy only if auto dlp mode is selected
  count  = local.is_auto_dlp_mode? 1 : 0

  // Project-level config. Only data in that project could be scanned
  #    parent = "projects/<project id>/locations/${local.dlp_region}"

  parent = "organizations/${var.dlp_bq_scan_org_id}/locations/${local.dlp_regional_end_point}"

  org_config {
    // The project that will run the scan. The DLP service account that exists within this project must have access to all resources that are profiled, and the cloud DLP API must be enabled
    project_id = var.project

    // The data to scan folder or project
    location {
      folder_id = var.dlp_bq_scan_folder_id
    }
  }

  location = local.dlp_regional_end_point

  // inspection template(s) that will be used to inspect BQ tables
  inspect_templates = local.dlp_inspection_templates_ids_list

  // Enabled target with filter on specific projects/datasets/tables
  targets {
    big_query_target {

      filter {
        tables {
          include_regexes {
            patterns {
              project_id_regex = var.dlp_bq_project_id_regex
              dataset_id_regex = var.dlp_bq_dataset_regex
              table_id_regex = var.dlp_bq_table_regex
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

  // Target to cover all "other" unmatched resources. Target is disabled, meaning, for all other matches than specified, do not profile.
  targets {
    big_query_target {
      filter {
        other_tables {}
      }
    }
  }

  actions {
    export_data {
      profile_table {
        project_id = var.project
        dataset_id = google_bigquery_dataset.results_dataset.dataset_id
        table_id   = var.auto_dlp_results_table_name
      }
    }
  }

  actions {
    pub_sub_notification {
      topic             = module.pubsub-tagger.topic-id
      // (Optional) The type of event that triggers a Pub/Sub. At most one PubSubNotification per EventType is permitted. Possible values are: NEW_PROFILE, CHANGED_PROFILE, SCORE_INCREASED, ERROR_CHANGED.
      event             = "NEW_PROFILE"
      // (Optional) How much data to include in the pub/sub message. Possible values are: TABLE_PROFILE, RESOURCE_NAME. For GCS, only RESOURCE_NAME is allowed
      detail_of_message = "RESOURCE_NAME"
    }
  }

  actions {
    pub_sub_notification {
      topic             = module.pubsub-tagger.topic-id
      // (Optional) The type of event that triggers a Pub/Sub. At most one PubSubNotification per EventType is permitted. Possible values are: NEW_PROFILE, CHANGED_PROFILE, SCORE_INCREASED, ERROR_CHANGED.
      event             = "CHANGED_PROFILE"
      // (Optional) How much data to include in the pub/sub message. Possible values are: TABLE_PROFILE, RESOURCE_NAME. For GCS, only RESOURCE_NAME is allowed
      detail_of_message = "RESOURCE_NAME"
    }
  }

  // PAUSED | RUNNING
  status = var.dlp_bq_create_configuration_in_paused_state ? "PAUSED" : "RUNNING"
}

// This module assigns roles and permissions to service accounts used in this solution on FOLDER level (and not the host project)
// The Terraform service account needs certain folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles folder level
module "data-folder-permissions-for-bq-discovery-stack" {

  # deploy only if auto dlp mode is selected
  count  = local.is_auto_dlp_mode? 1 : 0

  source = "./modules/data-folder-permissions-for-bq-discovery-stack"

  dlp_config_folder_id                    = var.dlp_bq_scan_folder_id

  # default: tagger@<host project id>.iam.gserviceaccount.com
  sa_tagger_email                         = google_service_account.sa_tagger.email
  # default: tag-dispatcher@<host project id>.iam.gserviceaccount.com
  sa_tagging_dispatcher_email             = google_service_account.sa_tagging_dispatcher.email
  # "service-${dlp scan config host project number}@dlp-api.iam.gserviceaccount.com"
  dlp_service_sa_email                    = local.dlp_service_account_email
  # default: sa-func-get-policy-tags@<host project id>.iam.gserviceaccount.com
  sa_bq_remote_func_get_policy_tags_email = module.bq-remote-func-get-table-policy-tags.cloud_function_sa_email

}
