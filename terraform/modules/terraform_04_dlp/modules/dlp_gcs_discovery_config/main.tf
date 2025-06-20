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

locals {
  dlp_region = var.data_region == "eu" ? "europe" : var.data_region
}

resource "google_data_loss_prevention_discovery_config" "dlp_gcs" {

  location = local.dlp_region

  parent = var.dlp_gcs_scan_parent_type == "organization"? "organizations/${var.dlp_gcs_scan_parent_id}/locations/${local.dlp_region}" : "projects/${var.dlp_gcs_scan_parent_id}/locations/${local.dlp_region}"

  // conditionally set the org_config if we are deploying to an org node
  dynamic "org_config" {
    for_each = var.dlp_gcs_scan_parent_type == "organization" ? [1] : []
    content {
      project_id = var.dlp_agent_project_id

      // The data to scan folder or project
      location {
        folder_id = var.dlp_gcs_scan_target_entity_id
      }
    }
  }

  // inspection template(s) that will be used to inspect GCS buckets
  inspect_templates = var.dlp_inspection_templates_ids_list

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
                project_id_regex = var.dlp_gcs_project_id_regex
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

        // (Optional) If you set this field, profiles are refreshed at this frequency regardless of whether the underlying data have changes. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY
        refresh_frequency = var.dlp_gcs_reprofile_frequency
      }
    }
  }

  // Target to cover all "other" unmatched resources. Target is disabled, meaning, for all other matches than specified, do not profile.
  targets {
    cloud_storage_target {
      filter {
        others {}
      }
      disabled {}
    }

  }

  actions {
    export_data {
      profile_table {
        project_id = var.publishing_project
        dataset_id = var.bq_results_dataset
        table_id   = var.dlp_gcs_bq_results_table_name
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
    for_each = var.dlp_gcs_apply_tags ? [1] : []
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
  status = var.dlp_gcs_create_configuration_in_paused_state ? "PAUSED" : "RUNNING"
}