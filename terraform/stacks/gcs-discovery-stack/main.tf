########################################################################################################################
#                                             DATA & LOCALS
########################################################################################################################

locals {
  dlp_region = var.data_region == "eu" ? "europe" : var.data_region

  tagging_dispatcher_gcs_service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.tagging_dispatcher_gcs_service_image}"

  tagger_gcs_service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.tagger_gcs_service_image}"
}

resource "google_data_loss_prevention_discovery_config" "dlp_gcs_org_folder" {

  // Project-level config. Only data in that project could be scanned
  #    parent = "projects/<project id>/locations/${local.dlp_region}"

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
        dataset_id = var.bq_results_dataset
        table_id   = var.dlp_gcs_bq_results_table_name
      }
    }
  }

  actions {
    pub_sub_notification {
      topic             = module.pubsub-tagger-gcs-for-dlp.topic-id
      // (Optional) The type of event that triggers a Pub/Sub. At most one PubSubNotification per EventType is permitted. Possible values are: NEW_PROFILE, CHANGED_PROFILE, SCORE_INCREASED, ERROR_CHANGED.
      event             = "NEW_PROFILE"
      // (Optional) How much data to include in the pub/sub message. Possible values are: TABLE_PROFILE, RESOURCE_NAME. For GCS, only RESOURCE_NAME is allowed
      detail_of_message = "RESOURCE_NAME"
    }
  }

  actions {
    pub_sub_notification {
      topic             = module.pubsub-tagger-gcs-for-dlp.topic-id
      // (Optional) The type of event that triggers a Pub/Sub. At most one PubSubNotification per EventType is permitted. Possible values are: NEW_PROFILE, CHANGED_PROFILE, SCORE_INCREASED, ERROR_CHANGED.
      event             = "CHANGED_PROFILE"
      // (Optional) How much data to include in the pub/sub message. Possible values are: TABLE_PROFILE, RESOURCE_NAME. For GCS, only RESOURCE_NAME is allowed
      detail_of_message = "RESOURCE_NAME"
    }
  }

  // PAUSED | RUNNING
  status = var.dlp_gcs_create_configuration_in_paused_state ? "PAUSED" : "RUNNING"
}

resource "google_service_account" "sa_tagging_dispatcher_gcs" {
  project = var.project
  account_id = var.sa_tagging_dispatcher_gcs
  display_name = "Runtime SA for Tagging Dispatcher GCS service"
}

resource "google_service_account" "sa_tagging_dispatcher_gcs_tasks" {
  project = var.project
  account_id = var.sa_tagging_dispatcher_gcs_tasks
  display_name = "To authorize PubSub Push requests to Tagging Dispatcher GCS Service"
}

resource "google_service_account_iam_member" "sa_tagging_dispatcher_gcs_account_user_sa_dispatcher_gcs_tasks" {
  service_account_id = google_service_account.sa_tagging_dispatcher_gcs.name
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.sa_tagging_dispatcher_gcs_tasks.email}"
}

module "cloud-run-tagging-dispatcher-gcs" {
  source                        = "../../modules/cloud-run"
  project                       = var.project
  region                        = var.compute_region
  service_image                 = local.tagging_dispatcher_gcs_service_image_uri
  service_name                  = var.tagging_dispatcher_gcs_service_name
  service_account_email         = google_service_account.sa_tagging_dispatcher_gcs.email
  invoker_service_account_email = google_service_account.sa_tagging_dispatcher_gcs_tasks.email
  # Dispatcher could take time to list large number of tables
  timeout_seconds               = var.dispatcher_service_timeout_seconds
  max_containers                = 1
  max_cpu                       = var.dispatcher_service_max_cpu
  max_memory                    = var.dispatcher_service_max_memory
  max_requests_per_container    = 1 # process one tagging dispatcher request at a time
  environment_variables         = [
    {
      name  = "PROJECT_ID",
      value = var.project
    },
    {
      name  = "TAGGER_TOPIC",
      value = module.pubsub-tagger-gcs-for-dispatcher.topic-name
    },
    {
      name  = "GCS_FLAGS_BUCKET",
      value = var.gcs_flags_bucket_name,
    },
    {
      name  = "DLP_RESULTS_DATASET",
      value = var.bq_results_dataset,
    },
    {
      name  = "DLP_RESULTS_TABLE",
      value = var.dlp_gcs_bq_results_table_name,
    },
    {
      name  = "DISPATCHER_RUNS_TABLE",
      value = google_bigquery_table.dispatcher_runs_gcs_table.id,
    }
  ]
}

module "pubsub-tagging-dispatcher-gcs" {
  source                                  = "../../modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = module.cloud-run-tagging-dispatcher-gcs.service_endpoint
  subscription_name                       = var.tagging_dispatcher_gcs_pubsub_sub
  subscription_service_account            = google_service_account.sa_tagging_dispatcher_gcs_tasks.email
  topic                                   = var.tagging_dispatcher_gcs_pubsub_topic
  topic_publishers_sa_emails              = [google_service_account.sa_workflows.email]
  # use a deadline large enough to process BQ listing for large scopes
  subscription_ack_deadline_seconds       = var.dispatcher_subscription_ack_deadline_seconds
  # avoid resending dispatcher messages if things went wrong and the msg was NAK (e.g. timeout expired, app error, etc)
  # min value must be at equal to the ack_deadline_seconds
  subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
}

resource "google_service_account" "sa_tagger_gcs" {
  project = var.project
  account_id = var.sa_tagger_gcs
  display_name = "Runtime SA for the Tagger GCS Service"
}

resource "google_service_account" "sa_tagger_gcs_tasks" {
  project = var.project
  account_id = var.sa_tagger_gcs_tasks
  display_name = "To authorize PubSub Push requests to Tagger GCS Service"
}

resource "google_service_account_iam_member" "sa_tagger_gcs_account_user_sa_tagger_gcs_tasks" {
  service_account_id = google_service_account.sa_tagger_gcs.name
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.sa_tagger_gcs_tasks.email}"
}

module "cloud-run-tagger-gcs" {
  source                        = "../../modules/cloud-run"
  project                       = var.project
  region                        = var.compute_region
  service_image                 = local.tagger_gcs_service_image_uri
  service_name                  = var.tagger_gcs_service_name
  service_account_email         = google_service_account.sa_tagger_gcs.email
  invoker_service_account_email = google_service_account.sa_tagger_gcs_tasks.email
  # Dispatcher could take time to list large number of tables
  timeout_seconds               = var.tagger_service_timeout_seconds
  # Discovery Tagging:
  #   GCS Tagger hits the DLP API (get file store profile) and Cloud Storage API (update bucket)
  #   DLP API: 600 requests per minute
  #   Storage API: NA
  # Dispatcher Tagging:
  #   Only hits the Storage API to add labels to buckets
  max_containers                = 100
  max_requests_per_container    = 800
  max_cpu                       = 8
  max_memory                    = "16Gi"
  environment_variables         = [
    {
      name  = "IS_DRY_RUN_LABELS",
      value = var.is_dry_run_labels,
    },
    {
      name  = "COMPUTE_REGION_ID",
      value = var.compute_region,
    },
    {
      name  = "PROJECT_ID",
      value = var.project,
    },
    {
      name  = "GCS_FLAGS_BUCKET",
      value = var.gcs_flags_bucket_name,
    },
    {
      name  = "INFO_TYPE_MAP",
      value = jsonencode(var.info_type_map),
    },
    {
      name  = "EXISTING_LABELS_REGEX",
      value = var.gcs_existing_labels_regex,
    }
  ]
}

module "pubsub-tagger-gcs-for-dlp" {
  source                                  = "../../modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = module.cloud-run-tagger-gcs.service_endpoint
  subscription_name                       = "${var.tagger_gcs_pubsub_sub}_for_dlp"
  subscription_service_account            = google_service_account.sa_tagger_gcs_tasks.email
  topic                                   = "${var.tagger_gcs_pubsub_topic}_for_dlp"
  topic_publishers_sa_emails              = [var.dlp_service_account_email]
  # use a deadline large enough to process BQ listing for large scopes
  subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  # avoid resending dispatcher messages if things went wrong and the msg was NAK (e.g. timeout expired, app error, etc)
  # min value must be at equal to the ack_deadline_seconds
  subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
  retain_acked_messages                   = var.retain_dlp_tagger_pubsub_messages # to enable replays for messages published by DLP

}

module "pubsub-tagger-gcs-for-dispatcher" {
  source                                  = "../../modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = module.cloud-run-tagger-gcs.service_endpoint
  subscription_name                       = "${var.tagger_gcs_pubsub_sub}_for_dispatcher"
  subscription_service_account            = google_service_account.sa_tagger_gcs_tasks.email
  topic                                   = "${var.tagger_gcs_pubsub_topic}_for_dispatcher"
  topic_publishers_sa_emails              = [google_service_account.sa_tagging_dispatcher_gcs.email]
  # use a deadline large enough to process BQ listing for large scopes
  subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  # avoid resending dispatcher messages if things went wrong and the msg was NAK (e.g. timeout expired, app error, etc)
  # min value must be at equal to the ack_deadline_seconds
  subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
}

### Permissions on flags bucket

resource "google_storage_bucket_iam_member" "sa_tagging_dispatcher_gcs_flags_bucket_admin" {
  bucket = var.gcs_flags_bucket_name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.sa_tagging_dispatcher_gcs.email}"
}

resource "google_storage_bucket_iam_member" "sa_tagger_gcs_flags_bucket_admin" {
  bucket = var.gcs_flags_bucket_name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.sa_tagger_gcs.email}"
}

# Helper functions for data analysis aand cost estimation
module "bq-remote-func-get-buckets-metadata" {
  source                         = "../../modules/bq-remote-function"
  function_name                  = var.bq_remote_func_get_buckets_metadata
  cloud_function_src_dir         = "../helpers/bq-remote-functions/get-buckets-metadata"
  cloud_function_temp_dir        = "/tmp/get-buckets-metadata.zip"
  service_account_name           = var.sa_bq_remote_func_get_buckets_metadata
  function_entry_point           = "process_request"
  env_variables                  = {}
  project                        = var.project
  compute_region                 = var.compute_region
  data_region                    = var.data_region
  bigquery_dataset_name          = var.bq_results_dataset
  deployment_procedure_path      = "modules/bq-remote-function/procedures/deploy_get_buckets_metadata_remote_func.tpl"
  cloud_functions_sa_extra_roles = []
}

locals {
  tagging_dispatcher_sa_roles = [
    "roles/bigquery.jobUser", # to run the query that reads DLP findings
    "roles/bigquery.dataEditor", # to insert dispatched tracking Ids to table dispatcher_runs
    "roles/batch.agentReporter", # to run Cloud Batch jobs
    "roles/logging.logWriter" # to run Cloud Batch jobs
  ]
}

resource "google_project_iam_member" "sa_tagging_dispatcher_roles_binding" {
  count = length(local.tagging_dispatcher_sa_roles)
  project = var.project
  role = local.tagging_dispatcher_sa_roles[count.index]
  member = "serviceAccount:${google_service_account.sa_tagging_dispatcher_gcs.email}"
}

### Workflows

resource "google_service_account" "sa_workflows" {
  project = var.project
  account_id = var.sa_workflows_gcs
  display_name = "Runtime SA for Cloud Workflow for BigQuery Dispatcher"
}

resource "google_workflows_workflow" "bq_tagging_dispatcher_workflow" {

  project  = var.project
  name     = var.workflows_gcs_name
  description = var.workflows_gcs_description
  region = var.compute_region

  service_account = google_service_account.sa_workflows.email

  deletion_protection = false

  source_contents = <<-EOF
- init:
    assign:
      - project: '${var.project}'
      - topic: ${module.pubsub-tagging-dispatcher-gcs.topic-id}
      - message:
          projectsRegex: ${var.dlp_gcs_project_id_regex}
          bucketsRegex: ${var.dlp_gcs_bucket_name_regex}
      - base64Msg: '$${base64.encode(json.encode(message))}'
- publish_message_to_topic:
    call: googleapis.pubsub.v1.projects.topics.publish
    args:
      topic: '$${topic}'
      body:
        messages:
          - data: '$${base64Msg}'
    result: publish_result
- return_result:
    return:
      message_id: '$${publish_result.messageIds[0]}'
EOF


}
