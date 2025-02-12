#   Copyright 2021 Google LLC
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

provider "google" {
  project                     = var.project
  region                      = var.compute_region
  impersonate_service_account = local.terraform_service_account_email
}

data google_project "gcp_project" {
  project_id = var.project
}

locals {
  // Which SA should have access to the GCS flags bucket?
  // In all deployments, use these SAs
  common_gcs_admins = [
    "serviceAccount:${module.common-stack.sa_tagging_dispatcher_email}",
    "serviceAccount:${module.common-stack.sa_tagger_email}"
  ]
  // In Inspection Mode deployment (is_auto_dlp = false) use these:
  inspection_gcs_admins = var.is_auto_dlp_mode ? [] : [
    "serviceAccount:${module.inspection-stack[0].sa_inspection_dispatcher_email}",
    "serviceAccount:${module.inspection-stack[0].sa_inspector_email}"
  ]

  tagging_dispatcher_service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.tagging_dispatcher_service_image}"

  inspection_dispatcher_service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.inspection_dispatcher_service_image}"

  inspector_service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.inspector_service_image}"

  tagger_service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.tagger_service_image}"

  dlp_service_account_email = "service-${data.google_project.gcp_project.number}@dlp-api.iam.gserviceaccount.com"

  cloud_scheduler_account_email = "service-${data.google_project.gcp_project.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"

  terraform_service_account_email = "${var.terraform_service_account}@${var.project}.iam.gserviceaccount.com"

  // create a list of distinct projects where data to be inspected resides
  data_projects = distinct(concat(
    flatten([for dataset in var.datasets_include_list : split(".", dataset)[0]]), // parse project_name from "project_name.dataset_name"
    var.projects_include_list // concat to the list of projects
  ))

  dlp_inspection_templates_ids_list = flatten([for obj in module.common-stack.dlp_inspection_templates_ids : obj["ids"]])
}


module "gcs" {
  source                             = "./modules/gcs"
  gcs_flags_bucket_name              = "${var.project}-${var.gcs_flags_bucket_name}"
  project                            = var.project
  region                             = var.compute_region # because it's used by the cloud run services
  # both dispatchers should be admins. Add the inspection-dispatcher-sa only if it's being deployed
  gcs_flags_bucket_admins            = var.is_auto_dlp_mode ? local.common_gcs_admins : concat(local.common_gcs_admins, local.inspection_gcs_admins)
  terraform_data_deletion_protection = var.terraform_data_deletion_protection
}

module "common-stack" {
  source                                       = "./stacks/common"
  classification_taxonomy                      = var.classification_taxonomy
  cloud_scheduler_account                      = local.cloud_scheduler_account_email
  cron_expression                              = var.tagging_cron_expression
  datasets_exclude_list                        = var.datasets_exclude_list
  datasets_include_list                        = var.datasets_include_list
  dispatcher_service_image                     = local.tagging_dispatcher_service_image_uri
  dlp_service_account                          = local.dlp_service_account_email
  domain_mapping                               = var.domain_mapping
  iam_mapping                                  = var.iam_mapping
  is_dry_run_tags                              = var.is_dry_run_tags
  is_dry_run_labels                            = var.is_dry_run_labels
  project                                      = var.project
  projects_include_list                        = var.projects_include_list
  compute_region                               = var.compute_region
  data_region                                  = var.data_region
  tables_exclude_list                          = var.tables_exclude_list
  tagger_service_image                         = local.tagger_service_image_uri
  bigquery_dataset_name                        = var.bigquery_dataset_name
  dispatcher_pubsub_sub                        = var.tagging_dispatcher_pubsub_sub
  dispatcher_pubsub_topic                      = var.tagging_dispatcher_pubsub_topic
  dispatcher_service_name                      = var.tagging_dispatcher_service_name
  log_sink_name                                = var.log_sink_name
  sa_tagger                                    = var.sa_tagger
  sa_tagger_tasks                              = var.sa_tagger_tasks
  scheduler_name                               = var.tagging_scheduler_name
  tagger_pubsub_sub                            = var.tagger_pubsub_sub
  tagger_pubsub_topic                          = var.tagger_pubsub_topic
  tagger_role                                  = var.tagger_role
  tagger_service_name                          = var.tagger_service_name
  is_auto_dlp_mode                             = var.is_auto_dlp_mode
  auto_dlp_results_table_name                  = var.auto_dlp_results_table_name
  standard_dlp_results_table_name              = var.standard_dlp_results_table_name
  sa_tagging_dispatcher                        = var.sa_tagging_dispatcher
  sa_tagging_dispatcher_tasks                  = var.sa_tagging_dispatcher_tasks
  data_catalog_taxonomy_activated_policy_types = var.data_catalog_taxonomy_activated_policy_types
  gcs_flags_bucket_name                        = module.gcs.create_gcs_flags_bucket_name

  dispatcher_service_timeout_seconds                 = var.dispatcher_service_timeout_seconds
  dispatcher_subscription_ack_deadline_seconds       = var.dispatcher_subscription_ack_deadline_seconds
  dispatcher_subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
  tagger_service_timeout_seconds                     = var.tagger_service_timeout_seconds
  tagger_subscription_ack_deadline_seconds           = var.tagger_subscription_ack_deadline_seconds
  tagger_subscription_message_retention_duration     = var.tagger_subscription_message_retention_duration
  promote_mixed_info_types                           = var.promote_mixed_info_types

  custom_info_types_dictionaries     = var.custom_info_types_dictionaries
  custom_info_types_regex            = var.custom_info_types_regex
  source_data_regions                = var.source_data_regions
  taxonomy_name_suffix               = var.taxonomy_name_suffix
  terraform_data_deletion_protection = var.terraform_data_deletion_protection
  retain_tagger_pubsub_messages      = var.retain_tagger_pubsub_messages
}

module "inspection-stack" {
  source = "./stacks/inspection"
  // deploy the inspection stack only if the we are not in auto_dlp_mode
  count  = var.is_auto_dlp_mode ? 0 : 1

  bigquery_dataset_name           = module.common-stack.bq_results_dataset
  cloud_scheduler_account         = local.cloud_scheduler_account_email
  cron_expression                 = var.inspection_cron_expression
  datasets_exclude_list           = var.datasets_exclude_list
  datasets_include_list           = var.datasets_include_list
  dispatcher_service_image        = local.inspection_dispatcher_service_image_uri
  dlp_inspection_templates_ids    = module.common-stack.dlp_inspection_templates_ids
  inspector_service_image         = local.inspector_service_image_uri
  project                         = var.project
  projects_include_list           = var.projects_include_list
  compute_region                  = var.compute_region
  data_region                     = var.data_region
  source_data_regions             = var.source_data_regions
  table_scan_limits_json_config   = jsonencode(var.table_scan_limits_json_config)
  tables_exclude_list             = var.tables_exclude_list
  tagger_topic_id                 = module.common-stack.tagger_topic_id
  dispatcher_pubsub_sub           = var.inspection_dispatcher_pubsub_sub
  dispatcher_pubsub_topic         = var.inspection_dispatcher_pubsub_topic
  dispatcher_service_name         = var.inspection_dispatcher_service_name
  inspector_pubsub_sub            = var.inspector_pubsub_sub
  inspector_pubsub_topic          = var.inspector_pubsub_topic
  inspector_service_name          = var.inspector_service_name
  sa_inspector                    = var.sa_inspector
  sa_inspector_tasks              = var.sa_inspector_tasks
  scheduler_name                  = var.inspection_scheduler_name
  standard_dlp_results_table_name = var.standard_dlp_results_table_name
  sa_inspection_dispatcher        = var.sa_inspection_dispatcher
  sa_inspection_dispatcher_tasks  = var.sa_inspection_dispatcher_tasks
  dlp_max_findings_per_item       = var.dlp_max_findings_per_item
  dlp_min_likelihood              = var.dlp_min_likelihood
  dlp_sampling_method             = var.dlp_sampling_method
  gcs_flags_bucket_name           = module.gcs.create_gcs_flags_bucket_name

  dispatcher_service_timeout_seconds                 = var.dispatcher_service_timeout_seconds
  dispatcher_subscription_ack_deadline_seconds       = var.dispatcher_subscription_ack_deadline_seconds
  dispatcher_subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
  inspector_service_timeout_seconds                  = var.inspector_service_timeout_seconds
  inspector_subscription_ack_deadline_seconds        = var.inspector_subscription_ack_deadline_seconds
  inspector_subscription_message_retention_duration  = var.inspector_subscription_message_retention_duration
  retain_inspector_pubsub_messages      = var.retain_inspector_pubsub_messages
}

# Helper functions for data analysis

##### Enable datastore API because the bq-remote-func-get-table-policy-tags function is using it as a cache layer

resource "google_project_service" "datastore_api" {
  service            = "datastore.googleapis.com"
  disable_on_destroy = false                     # Prevent accidental disabling during Terraform destroy
}

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
  bigquery_dataset_name          = module.common-stack.bq_results_dataset
  deployment_procedure_path      = "modules/bq-remote-function/procedures/deploy_get_policy_tags_remote_func.tpl"
  cloud_functions_sa_extra_roles = ["roles/datastore.user"]

  depends_on = [module.common-stack]
}

# Assign permissions for the service accounts used in this solution on the data projects when using standard mode.
# For this to run, the terraform service account must have permissions to set IAM policies on each data project. You can achieve this by running scripts/prepare_terraform_service_account_on_data_projects.sh "data-project-1" "data-project-2".
# If you can't grant the terraform account such access, this step can also be done via scripts/prepare_data_projects_for_standard_mode.sh by an authorized user
module "data_projects_permissions_in_standard_mode" {
  source = "./modules/data-project-permissions-in-standard-mode"
  // deploy this module only if we are in standard mode
  count  = var.is_auto_dlp_mode? 0 : length(local.data_projects)

  target_project                          = local.data_projects[count.index]
  sa_bq_remote_func_get_policy_tags_email = module.bq-remote-func-get-table-policy-tags.cloud_function_sa_email
  sa_dlp_email                            = local.dlp_service_account_email
  sa_inspection_dispatcher_email          = module.inspection-stack[0].sa_inspection_dispatcher_email
  sa_inspector_email                      = module.inspection-stack[0].sa_inspector_email
  sa_tagger_email                         = module.common-stack.sa_tagger_email
  sa_tagging_dispatcher_email             = module.common-stack.sa_tagging_dispatcher_email
}

### DLP for GCS modules

module "gcs-auto-dlp-stack" {
  source = "./stacks/gcs-auto-dlp"

  # stack-specific parameters
  dlp_gcs_scan_org_id = var.dlp_gcs_scan_org_id
  dlp_gcs_scan_folder_id = var.dlp_gcs_scan_folder_id
  tagging_dispatcher_gcs_service_image = var.tagging_dispatcher_gcs_service_image
  tagger_gcs_service_image = var.tagger_gcs_service_image
  gcs_tagging_scheduler_cron = var.gcs_tagging_scheduler_cron

  # common parameters
  bq_results_dataset = module.common-stack.bq_results_dataset
  cloud_scheduler_account_email = local.cloud_scheduler_account_email
  compute_region = var.compute_region
  data_region = var.data_region
  dispatcher_service_timeout_seconds = var.dispatcher_service_timeout_seconds
  dlp_inspection_templates_ids_list = local.dlp_inspection_templates_ids_list
  gar_docker_repo_name = var.gar_docker_repo_name
  gcs_flags_bucket_name = module.gcs.create_gcs_flags_bucket_name
  project = var.project
  tagger_service_timeout_seconds = var.tagger_service_timeout_seconds
  dispatcher_subscription_ack_deadline_seconds       = var.dispatcher_subscription_ack_deadline_seconds
  dispatcher_subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
  info_type_map                                      = module.common-stack.info_type_map
  is_dry_run_labels                                  = var.is_dry_run_labels
  tagger_subscription_ack_deadline_seconds           = var.tagger_subscription_ack_deadline_seconds
  tagger_subscription_message_retention_duration     = var.tagger_subscription_message_retention_duration
  dlp_service_account_email                          = local.dlp_service_account_email
  source_data_regions                                = var.source_data_regions
  dlp_gcs_bq_results_table_name = var.dlp_gcs_bq_results_table_name
  dlp_gcs_bucket_name_regex = var.dlp_gcs_bucket_name_regex
  dlp_gcs_create_configuration_in_paused_state = var.dlp_gcs_create_configuration_in_paused_state
  dlp_gcs_included_bucket_attributes = var.dlp_gcs_included_bucket_attributes
  dlp_gcs_included_object_attributes = var.dlp_gcs_included_object_attributes
  dlp_gcs_project_id_regex = var.dlp_gcs_project_id_regex
  dlp_gcs_reprofile_on_data_change = var.dlp_gcs_reprofile_on_data_change
  dlp_gcs_reprofile_on_inspection_template_update = var.dlp_gcs_reprofile_on_inspection_template_update
  gcs_tagging_scheduler_description = var.gcs_tagging_scheduler_description
  gcs_tagging_scheduler_name = var.gcs_tagging_scheduler_name
  sa_tagger_gcs = var.sa_tagger_gcs
  sa_tagger_gcs_tasks = var.sa_tagger_gcs_tasks
  sa_tagging_dispatcher_gcs = var.sa_tagging_dispatcher_gcs
  sa_tagging_dispatcher_gcs_tasks = var.sa_tagging_dispatcher_gcs_tasks
  tagger_gcs_pubsub_sub = var.tagger_gcs_pubsub_sub
  tagger_gcs_pubsub_topic = var.tagger_gcs_pubsub_topic
  tagger_gcs_service_name = var.tagger_gcs_service_name
  tagging_dispatcher_gcs_pubsub_sub = var.tagging_dispatcher_gcs_pubsub_sub
  tagging_dispatcher_gcs_pubsub_topic = var.tagging_dispatcher_gcs_pubsub_topic
  tagging_dispatcher_gcs_service_name = var.tagging_dispatcher_gcs_service_name
  bq_remote_func_get_buckets_metadata = var.bq_remote_func_get_buckets_metadata
  sa_bq_remote_func_get_buckets_metadata = var.sa_bq_remote_func_get_buckets_metadata
}

// This module assigns roles and permissions to service accounts used in this solution on FOLDER AND ORG levels (and not the host project)
// The Terraform service account needs certain org/folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles on org and folder level
module "data-folder-permissions-for-gcs-stack" {
  source = "./modules/data-folder-permissions-for-gcs-stack"

  dlp_config_org_id = var.dlp_gcs_scan_org_id
  dlp_config_folder_id = var.dlp_gcs_scan_folder_id

  # "service-${dlp scan config host project number}@dlp-api.iam.gserviceaccount.com"
  dlp_service_sa_email = local.dlp_service_account_email
  # <var.sa_tagging_dispatcher_gcs>@<host project name>.iam.gserviceaccount.com. Default: tag-dispatcher-gcs@<host project name>.iam.gserviceaccount.com
  dispatcher_sa_email = module.gcs-auto-dlp-stack.dispatcher_sa_email
  # <var.sa_tagger_gcs>@<host project name>.iam.gserviceaccount.com. Default: tagger-gcs@<host project name>.iam.gserviceaccount.com
  tagger_sa_email = module.gcs-auto-dlp-stack.tagger_sa_email
  # <var.sa_bq_remote_func_get_buckets_metadata>@<host project name>.iam.gserviceaccount.com. Default: sa-func-get-buckets-metadata@<host project name>.iam.gserviceaccount.com
  func_get_buckets_metadata_sa_email = module.gcs-auto-dlp-stack.func_get_buckets_metadata_sa_email
}

locals {
  dlp_region = var.data_region == "eu" ? "europe" : var.data_region
}

variable "dlp_bq_scan_org_id" {
  type = string
}

variable "dlp_bq_scan_folder_id" {
  type = string
}

variable "dlp_bq_create_configuration_in_paused_state" {
  type = bool
  description = "When set to true, the DLP discovery scan configuration is created in a paused state and must be resumed manually to allow confirmation and avoid DLP scan cost if there are mistakes or errors. When set to false, the discovery scan will start running upon creation"
  default = true
}

variable "dlp_bq_project_id_regex" {
  type        = string
  description = "Regex for project ids to be covered by the DLP scan for BigQuery. For organization-level configuration, if unset, will match all projects"
  default     = ".*"
}

variable "dlp_bq_dataset_regex" {
  type        = string
  description = "Regex to test the dataset name against during the DLP scan for BigQuery. if unset, this property matches all datasets"
  default     = ".*"
}

variable "dlp_bq_table_regex" {
  type        = string
  description = "Regex to test the table name against during the DLP scan for BigQuery.  if unset, this property matches all tables"
  default     = ".*"
}

variable "dlp_bq_table_types" {
  type = list(string)
  description = "Restrict dlp discovery service for BigQuery to specific table types"
  default = ["BIG_QUERY_TABLE_TYPE_TABLE", "BIG_QUERY_TABLE_TYPE_EXTERNAL_BIG_LAKE"]
}

variable "dlp_bq_reprofile_on_table_schema_update_frequency" {
  type = string
  description = "How frequently data profiles can be updated when a table schema is modified (i.e. columns). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
  default = "UPDATE_FREQUENCY_NEVER"
}

variable "dlp_bq_reprofile_on_table_data_update_frequency" {
  type = string
  description = "How frequently data profiles can be updated when a table data is modified (i.e. rows). Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
  default = "UPDATE_FREQUENCY_NEVER"
}

variable "dlp_bq_reprofile_on_inspection_template_update_frequency" {
  type = string
  description = "How frequently data profiles can be updated when the template is modified. Defaults to never. Possible values are: UPDATE_FREQUENCY_NEVER, UPDATE_FREQUENCY_DAILY, UPDATE_FREQUENCY_MONTHLY."
  default = "UPDATE_FREQUENCY_NEVER"
}

variable "dlp_bq_reprofile_on_schema_update_types" {
  type = list(string)
  description = "The type of events to consider when deciding if the table's schema has been modified and should have the profile updated. Defaults to NEW_COLUMN. Each value may be one of: SCHEMA_NEW_COLUMNS, SCHEMA_REMOVED_COLUMNS"
  default = ["SCHEMA_NEW_COLUMNS"]
}

variable "dlp_bq_reprofile_on_table_data_update_types" {
  type = list(string)
  description = "The type of events to consider when deciding if the table has been modified and should have the profile updated. Defaults to MODIFIED_TIMESTAMP Each value may be one of: TABLE_MODIFIED_TIMESTAMP"
  default = ["TABLE_MODIFIED_TIMESTAMP"]
}

resource "google_data_loss_prevention_discovery_config" "dlp_bq_org_folder" {

  // Project-level config. Only data in that project could be scanned
  #    parent = "projects/<project id>/locations/${local.dlp_region}"

  parent = "organizations/${var.dlp_bq_scan_org_id}/locations/${local.dlp_region}"

  org_config {
    // The project that will run the scan. The DLP service account that exists within this project must have access to all resources that are profiled, and the cloud DLP API must be enabled
    project_id = var.project

    // The data to scan folder or project
    location {
      folder_id = var.dlp_bq_scan_folder_id
    }
  }

  location = local.dlp_region

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
        dataset_id = module.common-stack.bq_results_dataset
        table_id   = var.auto_dlp_results_table_name
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
  status = var.dlp_bq_create_configuration_in_paused_state ? "PAUSED" : "RUNNING"
}

// This module assigns roles and permissions to service accounts used in this solution on FOLDER level (and not the host project)
// The Terraform service account needs certain folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles folder level
module "data-folder-permissions-for-bq-auto-dlp-stack" {
  source = "./modules/data-folder-permissions-for-bq-auto-dlp-stack"

  dlp_config_folder_id                    = var.dlp_bq_scan_folder_id

  # default: tagger@<host project id>.iam.gserviceaccount.com
  sa_tagger_email                         = module.common-stack.sa_tagger_email
  # default: tag-dispatcher@<host project id>.iam.gserviceaccount.com
  sa_tagging_dispatcher_email             = module.common-stack.sa_tagging_dispatcher_email
  # "service-${dlp scan config host project number}@dlp-api.iam.gserviceaccount.com"
  dlp_service_sa_email                    = local.dlp_service_account_email
  # default: sa-func-get-policy-tags@<host project id>.iam.gserviceaccount.com
  sa_bq_remote_func_get_policy_tags_email = module.bq-remote-func-get-table-policy-tags.cloud_function_sa_email

}
