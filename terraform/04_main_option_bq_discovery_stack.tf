locals {
  dlp_regional_end_point = var.data_region == "eu" ? "europe" : var.data_region
}


module "cloud-run-tagging-dispatcher" {
  source                        = "./modules/cloud-run"
  project                       = var.project
  region                        = var.compute_region
  service_image                 = local.tagging_dispatcher_service_image_uri
  service_name                  = var.tagging_dispatcher_service_name
  service_account_email         = google_service_account.sa_tagging_dispatcher.email
  invoker_service_account_email = google_service_account.sa_tagging_dispatcher_tasks.email
  # Dispatcher could take time to list large number of tables
  timeout_seconds               = var.dispatcher_service_timeout_seconds
  max_containers                = 1
  max_cpu                       = 2
  environment_variables         = [
    {
      name  = "TAGGER_TOPIC",
      value = module.pubsub-tagger-for-dispatcher.topic-name,
    },
    {
      name  = "COMPUTE_REGION_ID",
      value = var.compute_region,
    },
    {
      name  = "DATA_REGION_ID",
      value = var.data_region,
    },
    {
      name = "SOURCE_DATA_REGIONS",
      value = jsonencode(var.source_data_regions),
    },
    {
      name  = "PROJECT_ID",
      value = var.project,
    },
    {
      name  = "GCS_FLAGS_BUCKET",
      value = google_storage_bucket.gcs_flags_bucket.name,
    },
    {
      name  = "SOLUTION_DATASET",
      value = google_bigquery_dataset.results_dataset.dataset_id,
    },
    {
      name  = "DLP_TABLE_AUTO",
      value = local.auto_dlp_results_latest_view,
    },
    {
      name  = "LOGGING_TABLE",
      value = google_bigquery_table.logging_table.table_id
    },
    {
      name = "DLP_INSPECTION_TEMPLATES_IDS",
      value = jsonencode(local.created_dlp_inspection_templates),
    },
    {
      name  = "VIEW_INFOTYPE_POLICYTAGS_MAP",
      value = google_bigquery_table.config_view_infotypes_policytags_map.table_id
    },
    {
      name  = "VIEW_DATASET_DOMAIN_MAP",
      value = google_bigquery_table.config_view_dataset_domain_map.table_id
    },
    {
      name  = "VIEW_PROJECT_DOMAIN_MAP",
      value = google_bigquery_table.config_view_project_domain_map.table_id
    },
    {
      name  = "DEFAULT_DOMAIN_NAME",
      value = var.default_domain_name,
    },
    {
      name  = "DISPATCHER_RUNS_TABLE",
      value = google_bigquery_table.dispatcher_runs_bq_table.table_id,
    }
  ]
}

module "cloud-run-tagger" {
  source                        = "./modules/cloud-run"
  project                       = var.project
  region                        = var.compute_region
  service_image                 = local.tagger_service_image_uri
  service_name                  = var.tagger_service_name
  service_account_email         = google_service_account.sa_tagger.email
  invoker_service_account_email = google_service_account.sa_tagger_tasks.email
  # no more than 80 requests at a time to handle BigQuery API rate limiting
  max_containers                = 1
  max_requests_per_container    = 80
  # Tagger is using BigQuery BATCH queries that could take time to get started
  timeout_seconds               = var.tagger_service_timeout_seconds
  environment_variables         = [
    {
      name  = "IS_DRY_RUN_TAGS",
      value = var.is_dry_run_tags,
    },
    {
      name  = "IS_DRY_RUN_LABELS",
      value = var.is_dry_run_labels,
    },
    {
      name  = "TAXONOMIES",
      value = local.created_taxonomies,
    },
    {
      name  = "REGION_ID",
      value = var.compute_region,
    },
    {
      name  = "PROJECT_ID",
      value = var.project,
    },
    {
      name  = "GCS_FLAGS_BUCKET",
      value = google_storage_bucket.gcs_flags_bucket.name,
    },
    {
      name  = "DLP_DATASET",
      value = google_bigquery_dataset.results_dataset.dataset_id,
    },
    {
      name  = "DLP_TABLE_AUTO",
      value = local.auto_dlp_results_latest_view,
    },
    {
      name  = "VIEW_INFOTYPE_POLICYTAGS_MAP",
      value = google_bigquery_table.config_view_infotypes_policytags_map.table_id
    },
    {
      name  = "VIEW_DATASET_DOMAIN_MAP",
      value = google_bigquery_table.config_view_dataset_domain_map.table_id
    },
    {
      name  = "VIEW_PROJECT_DOMAIN_MAP",
      value = google_bigquery_table.config_view_project_domain_map.table_id
    },
    {
      name  = "INFO_TYPE_MAP",
      value = jsonencode(local.info_types_map),
    },
    {
      name  = "DEFAULT_DOMAIN_NAME",
      value = var.default_domain_name,
    },
    {
      name  = "EXISTING_LABELS_REGEX",
      value = var.bq_existing_labels_regex
    },
    {
      name  = "INFO_TYPE_POLICY_TAG_MAP",
      value = jsonencode(local.created_policy_tags)
    },
    {
      name  = "PROJECT_DOMAIN_MAP",
      value = jsonencode(local.project_and_domains_filtered)
    },
    {
      name  = "DATASET_DOMAIN_MAP",
      value = jsonencode(local.datasets_and_domains_filtered)
    },
    {
      name  = "DLP_PARENT",
      value = google_data_loss_prevention_discovery_config.dlp_bq_org_folder.parent
    },
    {
      name = "PROMOTE_DLP_OTHER_MATCHES"
      value = var.promote_dlp_other_matches
    }
  ]
}

module "pubsub-tagging-dispatcher" {
  source                                  = "./modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = module.cloud-run-tagging-dispatcher.service_endpoint
  subscription_name                       = var.tagging_dispatcher_pubsub_sub
  subscription_service_account            = google_service_account.sa_tagging_dispatcher_tasks.email
  topic                                   = var.tagging_dispatcher_pubsub_topic
  topic_publishers_sa_emails              = [local.cloud_scheduler_account_email]
  # use a deadline large enough to process BQ listing for large scopes
  subscription_ack_deadline_seconds       = var.dispatcher_subscription_ack_deadline_seconds
  # avoid resending dispatcher messages if things went wrong and the msg was NAK (e.g. timeout expired, app error, etc)
  # min value must be at equal to the ack_deadline_seconds
  subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration

}

module "pubsub-tagger-for-dlp" {
  source                                  = "./modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = "${module.cloud-run-tagger.service_endpoint}/discovery-service-handler"
  subscription_name                       = "${var.tagger_pubsub_sub}_for_dlp"
  subscription_service_account            = google_service_account.sa_tagger_tasks.email
  topic                                   = "${var.tagger_pubsub_topic}_for_dlp"
  // DLP service account must be able to publish messages to the Tagger
  topic_publishers_sa_emails              = [local.dlp_service_account_email]
  # 10m is max allowed
  subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  # How long to retain unacknowledged messages in the subscription's backlog, from the moment a message is published.
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions
  subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
  retain_acked_messages                   = var.retain_dlp_tagger_pubsub_messages # to replay messages generated by dlp
}

module "pubsub-tagger-for-dispatcher" {
  source                                  = "./modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = "${module.cloud-run-tagger.service_endpoint}/tagging-dispatcher-handler"
  subscription_name                       = "${var.tagger_pubsub_sub}_for_dispatcher"
  subscription_service_account            = google_service_account.sa_tagger_tasks.email
  topic                                   = "${var.tagger_pubsub_topic}_for_dispatcher"
  // DLP service account must be able to publish messages to the Tagger
  topic_publishers_sa_emails              = [google_service_account.sa_tagging_dispatcher.email]
  # 10m is max allowed
  subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  # How long to retain unacknowledged messages in the subscription's backlog, from the moment a message is published.
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions
  subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
}

resource "google_cloud_scheduler_job" "scheduler_job" {
  project = var.project
  region = var.compute_region
  name             = var.tagging_scheduler_name
  description      = var.tagging_scheduler_description
  schedule         = var.tagging_cron_expression

  retry_config {
    retry_count = 0
  }

  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = module.pubsub-tagging-dispatcher.topic-id
    data       = base64encode(jsonencode({
      projectsRegex = var.dlp_bq_project_id_regex
      datasetsRegex = var.dlp_bq_dataset_regex
      tablesRegex = var.dlp_bq_table_regex
    }))
  }

  depends_on = [google_project_service.enable_appengine]
}

### Data Catalog Policy Tags ####
module "data-catalog" {
  count = length(local.taxonomies_to_be_created)
  source = "./modules/data-catalog"
  project = var.project
  region = local.taxonomies_to_be_created[count.index][0]

  domain = local.taxonomies_to_be_created[count.index][1]
  taxonomy_number = local.taxonomies_to_be_created[count.index][2]

  // only use the nodes that are marked for taxonomy number x
  classification_taxonomy = [for x in var.classification_taxonomy: x if x["taxonomy_number"] == local.taxonomies_to_be_created[count.index][2]]

  data_catalog_taxonomy_activated_policy_types = var.data_catalog_taxonomy_activated_policy_types
  taxonomy_name_suffix = var.taxonomy_name_suffix
}

############## Service Accounts ######################################

resource "google_service_account" "sa_tagging_dispatcher" {
  project = var.project
  account_id = var.sa_tagging_dispatcher
  display_name = "Runtime SA for Tagging Dispatcher service"
}

resource "google_service_account" "sa_tagger" {
  project = var.project
  account_id = var.sa_tagger
  display_name = "Runtime SA for Tagger service"
}

resource "google_service_account" "sa_tagging_dispatcher_tasks" {
  project = var.project
  account_id = var.sa_tagging_dispatcher_tasks
  display_name = "To authorize PubSub Push requests to Tagging Dispatcher Service"
}

resource "google_service_account" "sa_tagger_tasks" {
  project = var.project
  account_id = var.sa_tagger_tasks
  display_name = "To authorize PubSub Push requests to Tagger Service"
}

############## Service Accounts Access ################################

# Use google_project_iam_member because it's Non-authoritative.
# It Updates the IAM policy to grant a role to a new member.
# Other members for the role for the project are preserved.


#### Dispatcher Tasks Permissions ###

resource "google_service_account_iam_member" "sa_tagging_dispatcher_account_user_sa_dispatcher_tasks" {
  service_account_id = google_service_account.sa_tagging_dispatcher.name
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.sa_tagging_dispatcher_tasks.email}"
}

#### Dispatcher SA Permissions ###

# Grant sa_dispatcher access to submit query jobs
resource "google_project_iam_member" "sa_tagging_dispatcher_bq_job_user" {
  project = var.project
  role = "roles/bigquery.jobUser"
  member = "serviceAccount:${google_service_account.sa_tagging_dispatcher.email}"
}

// tagging dispatcher needs to read data from dlp results table and views created inside the solution-managed dataset and writing to dispatcher_runs
// e.g. listing tables to be tagged
resource "google_bigquery_dataset_access" "sa_tagging_dispatcher_bq_dataset_editor" {
  dataset_id    = google_bigquery_dataset.results_dataset.dataset_id
  role          = "roles/bigquery.dataEditor"
  user_by_email = google_service_account.sa_tagging_dispatcher.email
}



#### Tagger Tasks SA Permissions ###

resource "google_service_account_iam_member" "sa_tagger_account_user_sa_tagger_tasks" {
  service_account_id = google_service_account.sa_tagger.name
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.sa_tagger_tasks.email}"
}

#### Tagger SA Permissions ###

resource "google_project_iam_custom_role" "tagger-role" {
  project = var.project
  role_id = var.tagger_role
  title = var.tagger_role
  description = "Used to grant permissions to sa_tagger"
  permissions = [
    "bigquery.tables.setCategory",
    "datacatalog.taxonomies.get"]
}

resource "google_project_iam_member" "sa_tagger_role" {
  project = var.project
  role = google_project_iam_custom_role.tagger-role.name
  member = "serviceAccount:${google_service_account.sa_tagger.email}"
}

// tagger needs to read data from views created inside the solution-managed dataset
// e.g. dlp results view
resource "google_bigquery_dataset_access" "sa_tagger_bq_dataset_reader" {
  dataset_id    = google_bigquery_dataset.results_dataset.dataset_id
  role          = "roles/bigquery.dataViewer"
  user_by_email = google_service_account.sa_tagger.email
}

# to submit query jobs
resource "google_project_iam_member" "sa_tagger_bq_job_user" {
  project = var.project
  role = "roles/bigquery.jobUser"
  member = "serviceAccount:${google_service_account.sa_tagger.email}"
}


############## DLP Service Account ################################################

# DLP SA must read BigQuery columns tagged by solution-managed taxonomies
resource "google_project_iam_member" "dlp_sa_binding" {
  project = var.project
  role = "roles/datacatalog.categoryFineGrainedReader"
  member = "serviceAccount:${local.dlp_service_account_email}"
}

# DLP SA must write results to BigQuery table inside of the solution dataset
resource "google_bigquery_dataset_iam_member" "dlp_access_bq_dataset" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  role = "roles/bigquery.dataEditor"
  member = "serviceAccount:${local.dlp_service_account_email}"
}


## Data Catalog Taxonomies Permissions ##


locals {

  # For each parent tag: omit the tag_id and lookup the list of IAM members to grant access to
  parent_tags_with_members_list = [for parent_tag in local.created_parent_tags:
  {
    policy_tag_name = parent_tag["id"]
    # lookup the iam_mapping variable with the key <domain> and then sub-key <classification>
    # parent_tag.display_name is the classification

    # if no iam_mapping is provided, then assign an empty list of IAM members for that tag,
    # if not, get the configured IAM members for the classification level of that tag
    iam_members = length(var.iam_mapping) == 0? [] : lookup(
      // the domain-specific IAM mapping entry
      var.iam_mapping[parent_tag["domain"]],
      // The parent tag classification used as the display name
      parent_tag["display_name"],
      // if no IAM list is found for that domain-classification, use an empty list for iam members
      []
    )

  }]

  // flatten the iam_members list inside of parent_tags_with_members_list
  iam_members_list = flatten([for entry in local.parent_tags_with_members_list:[
  for member in lookup(entry, "iam_members", "NA"):
  {
    policy_tag_name = lookup(entry, "policy_tag_name", "NA")
    iam_member = member
  }
  ]])
}

# Grant permissions for every member in the iam_members_list
resource "google_data_catalog_policy_tag_iam_member" "policy_tag_reader" {
  provider = google
  count = length(local.iam_members_list)
  policy_tag = local.iam_members_list[count.index]["policy_tag_name"]
  role = "roles/datacatalog.categoryFineGrainedReader"
  member = local.iam_members_list[count.index]["iam_member"]
}

# Helper functions for data analysis

resource "google_firestore_database" "datastore_mode_database" {
  project                           = var.project
  name                              = var.datastore_database_name
  location_id                       = var.compute_region
  type                              = "DATASTORE_MODE"
  concurrency_mode                  = "OPTIMISTIC"
  app_engine_integration_mode       = "DISABLED"
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_DISABLED"
  delete_protection_state           = "DELETE_PROTECTION_DISABLED"
  deletion_policy                   = "DELETE"

  depends_on = [google_project_service.datastore_api]
}

module "bq-remote-func-get-table-policy-tags" {
  source                         = "./modules/bq-remote-function"
  function_name                  = var.bq_remote_func_get_policy_tags_name
  cloud_function_src_dir         = "../helpers/bq-remote-functions/get-policy-tags"
  cloud_function_temp_dir        = "/tmp/get-policy-tags.zip"
  service_account_name           = var.sa_bq_remote_func_get_policy_tags
  function_entry_point           = "process_request"
  // add more env_variables using merge({key=value}, {key=value}, etc}
  env_variables                  = {"DATASTORE_CACHE_DB_NAME" = var.datastore_database_name}
  project                        = var.project
  compute_region                 = var.compute_region
  data_region                    = var.data_region
  bigquery_dataset_name          = google_bigquery_dataset.results_dataset.dataset_id
  deployment_procedure_path      = "modules/bq-remote-function/procedures/deploy_get_policy_tags_remote_func.tpl"
  cloud_functions_sa_extra_roles = ["roles/datastore.user"]
}

resource "google_storage_bucket_iam_member" "gcs_flags_bucket_iam_member_sa_tagging_dispatcher" {
  bucket = google_storage_bucket.gcs_flags_bucket.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.sa_tagging_dispatcher.email}"
}

resource "google_storage_bucket_iam_member" "gcs_flags_bucket_iam_member_sa_tagger" {
  bucket = google_storage_bucket.gcs_flags_bucket.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.sa_tagger.email}"
}

############## DLP DISCOVERY SERVICE ################

resource "google_data_loss_prevention_discovery_config" "dlp_bq_org_folder" {

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
      topic             = module.pubsub-tagger-for-dlp.topic-id
      // (Optional) The type of event that triggers a Pub/Sub. At most one PubSubNotification per EventType is permitted. Possible values are: NEW_PROFILE, CHANGED_PROFILE, SCORE_INCREASED, ERROR_CHANGED.
      event             = "NEW_PROFILE"
      // (Optional) How much data to include in the pub/sub message. Possible values are: TABLE_PROFILE, RESOURCE_NAME. For GCS, only RESOURCE_NAME is allowed
      detail_of_message = "RESOURCE_NAME"
    }
  }

  actions {
    pub_sub_notification {
      topic             = module.pubsub-tagger-for-dlp.topic-id
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
