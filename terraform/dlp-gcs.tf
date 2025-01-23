### GCS Inspection via DLP Discovery Services

########################################################################################################################
#                                             VARIABLES
########################################################################################################################

## REQUIRED VARIABLES

variable "dlp_gcs_scan_org_id" {
  type        = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
}

variable "dlp_gcs_scan_folder_id" {
  type        = number
  description = "GCP folder ID that will be scanned by DLP discovery service for GCS"
}

## Default value variables

variable "dlp_gcs_project_id_regex" {
  type        = string
  description = "Regex for project ids to be covered by the DLP scan of GCS buckets. For organization-level configuration, if unset, will match all projects"
  default     = ".*"
}

variable "dlp_gcs_bucket_name_regex" {
  type        = string
  description = "Regex to test the bucket name against during the DLP scan. If empty, all buckets match"
  default     = ".*"
}

variable "dlp_gcs_bq_results_table_name" {
  type        = string
  description = "Name of the table that DLP will create to save the findings. This will be created in the solution dataset"
  default     = "dlp_discovery_services_gcs_results"
}

variable "dlp_gcs_included_object_attributes" {
  type = list(string)
  description = "Only objects with the specified attributes will be scanned. If an object has one of the specified attributes but is inside an excluded bucket, it will not be scanned. Defaults to [ALL_SUPPORTED_OBJECTS]. A profile will be created even if no objects match the included_object_attributes. Each value may be one of: ALL_SUPPORTED_OBJECTS, STANDARD, NEARLINE, COLDLINE, ARCHIVE, REGIONAL, MULTI_REGIONAL, DURABLE_REDUCED_AVAILABILITY."
  default = ["ALL_SUPPORTED_OBJECTS"]
}

variable "dlp_gcs_included_bucket_attributes" {
  type = list(string)
  description = "Only objects with the specified attributes will be scanned. Defaults to [ALL_SUPPORTED_BUCKETS] if unset. Each value may be one of: ALL_SUPPORTED_BUCKETS, AUTOCLASS_DISABLED, AUTOCLASS_ENABLED."
  default = ["ALL_SUPPORTED_BUCKETS"]
}

variable "dlp_gcs_reprofile_on_inspection_template_update" {
  type = string
  description = "How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
  default = "UPDATE_FREQUENCY_NEVER"
}

variable "dlp_gcs_reprofile_on_data_change" {
  type = string
  description = "If you set this field, profiles are refreshed at this frequency regardless of whether the underlying tables have changes. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY"
  default = "UPDATE_FREQUENCY_NEVER"
}

variable "dlp_gcs_create_configuration_in_paused_state" {
  type = bool
  description = "When set to true, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to false, the discovery scan will start running upon creation"
  default = true
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
#    parent = "projects/bqsc-marketing-v1/locations/${local.dlp_region}"

  parent = "organizations/${var.dlp_gcs_scan_org_id}/locations/${local.dlp_region}"
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
#          project_id  = ""
#        }
      }

      //  (Optional) In addition to matching the filter, these conditions must be true before a profile is generated for a bucket
      conditions {
        // (Optional) File store must have been created after this date. Used to avoid backfilling. A timestamp in RFC3339 UTC "Zulu" format with nanosecond resolution and upto nine fractional digits.
#        created_after = "2023-10-02T15:01:23Z"

        // (Optional) Duration format. Minimum age a file store must have. If set, the value must be 1 hour or greater.
#        min_age = "10800s"

        cloud_storage_conditions {

          // (Optional) Only objects with the specified attributes will be scanned. Defaults to [ALL_SUPPORTED_BUCKETS] if unset.
          // Each value may be one of: ALL_SUPPORTED_BUCKETS, AUTOCLASS_DISABLED, AUTOCLASS_ENABLED.
          included_bucket_attributes = var.dlp_gcs_included_bucket_attributes

          // (Optional) Only objects with the specified attributes will be scanned.
          // If an object has one of the specified attributes but is inside an excluded bucket, it will not be scanned. Defaults to [ALL_SUPPORTED_OBJECTS].
          // A profile will be created even if no objects match the included_object_attributes.
          // Each value may be one of: ALL_SUPPORTED_OBJECTS, STANDARD, NEARLINE, COLDLINE, ARCHIVE, REGIONAL, MULTI_REGIONAL, DURABLE_REDUCED_AVAILABILITY.
          included_object_attributes = var.dlp_gcs_included_object_attributes
        }
      }

      // (Optional) How often and when to update profiles. New buckets that match both the filter and conditions are scanned as quickly as possible depending on system capacity
      generation_cadence {

        // (Optional) Governs when to update data profiles when the inspection rules defined by the InspectTemplate change. If not set, changing the template will not cause a data profile to update
        inspect_template_modified_cadence {

          // (Required) How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY.
          frequency = var.dlp_gcs_reprofile_on_inspection_template_update
        }

        // (Optional) If you set this field, profiles are refreshed at this frequency regardless of whether the underlying tables have changes. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY
        refresh_frequency = var.dlp_gcs_reprofile_on_data_change
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
      topic             = module.common-stack.tagger_topic_id
      // (Optional) The type of event that triggers a Pub/Sub. At most one PubSubNotification per EventType is permitted. Possible values are: NEW_PROFILE, CHANGED_PROFILE, SCORE_INCREASED, ERROR_CHANGED.
      event             = "NEW_PROFILE"
      // (Optional) How much data to include in the pub/sub message. Possible values are: TABLE_PROFILE, RESOURCE_NAME. For GCS, only RESOURCE_NAME is allowed
      detail_of_message = "RESOURCE_NAME"
    }
  }

  actions {
    pub_sub_notification {
      topic             = module.common-stack.tagger_topic_id
      // (Optional) The type of event that triggers a Pub/Sub. At most one PubSubNotification per EventType is permitted. Possible values are: NEW_PROFILE, CHANGED_PROFILE, SCORE_INCREASED, ERROR_CHANGED.
      event             = "CHANGED_PROFILE"
      // (Optional) How much data to include in the pub/sub message. Possible values are: TABLE_PROFILE, RESOURCE_NAME. For GCS, only RESOURCE_NAME is allowed
      detail_of_message = "RESOURCE_NAME"
    }
  }

  // PAUSED | RUNNING
  status = var.dlp_gcs_create_configuration_in_paused_state ? "PAUSED" : "RUNNING"
}