### GCS Inspection via DLP Discovery Services

########################################################################################################################
#                                             VARIABLES
########################################################################################################################

variable "dlp_gcs_scan_org_id" {
  type = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
}

variable "dlp_gcs_scan_folder_id" {
  type        = number
  description = "GCP folder ID that will be scanned by DLP discovery service for GCS"
}

variable "dlp_gcs_project_id_regex" {
  type        = string
  description = "Regex for project ids to be covered by the DLP scan of GCS buckets. For organization-level configuration, if unset, will match all projects"
  default = ".*"
}

variable "dlp_gcs_bucket_name_regex" {
  type        = string
  description = "Regex to test the bucket name against during the DLP scan. If empty, all buckets match"
  default = ".*"
}

variable "dlp_gcs_bq_results_table_name" {
  type = string
  description = "Name of the table that DLP will create to save the findings. This will be created in the solution dataset"
  default = "dlp_discovery_services_gcs_results"
}

########################################################################################################################
#                                             DATA & LOCALS
########################################################################################################################

locals {
  dlp_region = var.data_region == "eu" ? "europe" : var.data_region
}

########################################################################################################################
#                                             RESOURCES
########################################################################################################################

resource "google_data_loss_prevention_discovery_config" "dlp_gcs_org_folder" {

  // Project-level config. Only data in that project could be scanned
  #  parent = "projects/${var.project}/locations/${local.dlp_region}"

  parent   = "organizations/${var.dlp_gcs_scan_org_id}/locations/${local.dlp_region}"
  org_config {
    // The project that will run the scan. The DLP service account that exists within this project must have access to all resources that are profiled, and the cloud DLP API must be enabled
    project_id = var.project

    // The data to scan folder or project
    location {
      folder_id = var.dlp_gcs_scan_folder_id
    }
  }

  location = local.dlp_region

  // inspection template(s) that will be used to inspect GCS buckets
  inspect_templates = local.dlp_inspection_templates_ids_list

  // Enabled target with filter on specific projects/buckets
  targets {

    cloud_storage_target {
      filter {

        // (Optional) A specific set of buckets for this filter to apply to.
        collection {
          include_regexes {
            patterns {
              cloud_storage_regex {
                // For organizations, if unset, will match all projects.
                project_id_regex  = var.dlp_gcs_project_id_regex
                // Regex to test the bucket name against. If empty, all buckets match. Example: "marketing2021" or "(marketing)\d{4}" will both match the bucket gs://marketing2021
                bucket_name_regex = var.dlp_gcs_bucket_name_regex
              }
            }

          }
        }

        // (Optional) The bucket to scan.
        #        cloud_storage_resource_reference {
        #          // (Optional) The bucket to scan.
        #          bucket_name = ""
        #          //(Optional) If within a project-level config, then this must match the config's project id.
        #          project_id = ""
        #        }
      }

      //  (Optional) In addition to matching the filter, these conditions must be true before a profile is generated for a bucket
      // conditions {}

      // (Optional) How often and when to update profiles. New buckets that match both the filter and conditions are scanned as quickly as possible depending on system capacity
      generation_cadence {

        // (Optional) Governs when to update data profiles when the inspection rules defined by the InspectTemplate change. If not set, changing the template will not cause a data profile to update
        inspect_template_modified_cadence {

          // (Required) How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
          frequency = "UPDATE_FREQUENCY_NEVER"
        }

        // (Optional) Data changes (non-schema changes) in Cloud SQL tables can't trigger re-profiling. If you set this field, profiles are refreshed at this frequency regardless of whether the underlying tables have changes. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY
        refresh_frequency = "UPDATE_FREQUENCY_NEVER"
      }
    }
  }

  // Target to cover all "other" unmatched resources. Target is disabled, meaning, for all other matches than specified, do not profile.
  targets {
    cloud_storage_target {
      disabled {}
      filter {
        others {}
      }
    }

  }

  actions {
    export_data {
      profile_table {
        project_id = var.project
        dataset_id = module.common-stack.bq_results_dataset
        table_id   = var.dlp_gcs_bq_results_table_name
      }
    }
  }

  actions {
    pub_sub_notification {
      topic = module.common-stack.tagger_topic_id
      // (Optional) The type of event that triggers a Pub/Sub. At most one PubSubNotification per EventType is permitted. Possible values are: NEW_PROFILE, CHANGED_PROFILE, SCORE_INCREASED, ERROR_CHANGED.
      event = "NEW_PROFILE"
      // (Optional) How much data to include in the pub/sub message. Possible values are: TABLE_PROFILE, RESOURCE_NAME. For GCS, only RESOURCE_NAME is allowed
      detail_of_message = "RESOURCE_NAME"
    }
  }

  actions {
    pub_sub_notification {
      topic = module.common-stack.tagger_topic_id
      // (Optional) The type of event that triggers a Pub/Sub. At most one PubSubNotification per EventType is permitted. Possible values are: NEW_PROFILE, CHANGED_PROFILE, SCORE_INCREASED, ERROR_CHANGED.
      event = "CHANGED_PROFILE"
      // (Optional) How much data to include in the pub/sub message. Possible values are: TABLE_PROFILE, RESOURCE_NAME. For GCS, only RESOURCE_NAME is allowed
      detail_of_message = "RESOURCE_NAME"
    }
  }

  // create the config in paused status for manual confirmation and avoiding DLP cost due to mistakes
  status = "PAUSED"
}