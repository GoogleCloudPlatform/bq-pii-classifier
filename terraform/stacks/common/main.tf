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


# Enable APIS
resource "google_project_service" "enable_service_usage_api" {
  project = var.project
  service = "serviceusage.googleapis.com"

  disable_on_destroy = false
}

# Enable Cloud Scheduler API
resource "google_project_service" "enable_appengine" {
  project = var.project
  service = "appengine.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

# Enable Cloud Build API
resource "google_project_service" "enable_cloud_build" {
  project = var.project
  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false
}

# Enables the Cloud Run API
resource "google_project_service" "run_api" {
  project = var.project
  service = "run.googleapis.com"

  disable_on_destroy = false
}

locals {

  project_and_domains = distinct([
  for entry in var.domain_mapping : {
    project = entry["project"],
    domain  = entry["domain"]
  }
  ])

  # Only projects with configured domains
  project_and_domains_filtered = [for entry in local.project_and_domains : entry if entry["domain"] != ""]

  datasets_and_domains = distinct(flatten([
  for entry in var.domain_mapping : [
  for dataset in lookup(entry, "datasets", []) : {
    project = entry["project"],
    dataset = dataset["name"],
    domain  = dataset["domain"]
  }
  ]
  ]))

  # Only datasets with configured domains
  datasets_and_domains_filtered = [for entry in local.datasets_and_domains : entry if entry["domain"] != ""]

  # Get distinct domains set on project entries
  project_domains = distinct([
  for entry in local.project_and_domains_filtered : entry["domain"]
  ])

  # Get distinct domains set on dataset level
  dataset_domains = distinct([
  for entry in local.datasets_and_domains_filtered : entry["domain"]
  ])

  // Concat project and dataset domains and filter out empty strings
  domains = distinct(concat(local.project_domains, local.dataset_domains))

  # comma separated string with taxonomy names
  created_taxonomies = join(",", [for taxonomy in module.data-catalog[*].created_taxonomy : taxonomy.name])

  // one list of all policy tags generated across domain taxonomies
  // each element of the list is a map with three attributes (policy_tag_id, domain, classification, info_type, region)
  created_policy_tags = flatten(module.data-catalog[*].created_children_tags)

  created_parent_tags = flatten(module.data-catalog[*].created_parent_tags)

  auto_dlp_results_latest_view = "${var.auto_dlp_results_table_name}_latest_v1"

  taxonomy_numbers = distinct([for x in var.classification_taxonomy: x["taxonomy_number"]])

  // this return a list of lists like [ ["europe-west3","dwh","1"], ["europe-west3","dwh","2"], ["europe-west3","marketing","1"], ["europe-west3","marketing","2"], etc ]
  taxonomies_to_be_created = setproduct(tolist(var.source_data_regions), local.domains, local.taxonomy_numbers)

  inspection_templates_count = max([for x in var.classification_taxonomy: x["inspection_template_number"]]...)

  info_types_map = {
  for item in var.classification_taxonomy : item["info_type"] => {
    classification = item["classification"],
    labels         = item["labels"]
  }
  }

  created_dlp_inspection_templates = module.dlp[*].created_inspection_templates
}

module "data-catalog" {
  count = length(local.taxonomies_to_be_created)
  source = "../../modules/data-catalog"
  project = var.project
  region = local.taxonomies_to_be_created[count.index][0]

  domain = local.taxonomies_to_be_created[count.index][1]
  taxonomy_number = local.taxonomies_to_be_created[count.index][2]

  // only use the nodes that are marked for taxonomy number x
  classification_taxonomy = [for x in var.classification_taxonomy: x if x["taxonomy_number"] == local.taxonomies_to_be_created[count.index][2]]

  data_catalog_taxonomy_activated_policy_types = var.data_catalog_taxonomy_activated_policy_types
  taxonomy_name_suffix = var.taxonomy_name_suffix
}


module "bigquery" {
  source          = "../../modules/bigquery"
  project         = var.project
  region          = var.data_region
  dataset         = var.bigquery_dataset_name
  logging_sink_sa = module.cloud_logging.service_account

  # Data for config views
  created_policy_tags             = local.created_policy_tags
  dataset_domains_mapping         = local.datasets_and_domains_filtered
  projects_domains_mapping        = local.project_and_domains_filtered
  standard_dlp_results_table_name = var.standard_dlp_results_table_name
  inspection_templates_count = local.inspection_templates_count
  terraform_data_deletion_protection = var.terraform_data_deletion_protection
  default_labels = var.default_labels
}

module "cloud_logging" {
  source = "../../modules/cloud-logging"

  dataset       = module.bigquery.results_dataset
  project       = var.project
  log_sink_name = var.log_sink_name
}

// DLP

# deploy 1 dlp inspection template in each source data region
module "dlp" {
  count = length(var.source_data_regions)
  source                  = "../../modules/dlp"
  project                 = var.project
  region                  = tolist(var.source_data_regions)[count.index] # create inspection template in the same region as source data
  classification_taxonomy = var.classification_taxonomy

  custom_info_types_dictionaries = var.custom_info_types_dictionaries
  custom_info_types_regex        = var.custom_info_types_regex
}

module "cloud_scheduler" {
  source         = "../../modules/cloud-scheduler"
  project        = var.project
  region         = var.compute_region
  scheduler_name = var.scheduler_name

  target_uri = module.pubsub-tagging-dispatcher.topic-id

  datasets_include_list = var.datasets_include_list
  projects_include_list = var.projects_include_list
  datasets_exclude_list = var.datasets_exclude_list
  tables_exclude_list   = var.tables_exclude_list
  cron_expression       = var.cron_expression

  depends_on = [google_project_service.enable_appengine]
}

module "iam" {
  source = "../../modules/iam"
  project = var.project
  sa_tagger = var.sa_tagger
  sa_tagger_tasks = var.sa_tagger_tasks
  taxonomy_parent_tags = local.created_parent_tags
  iam_mapping = var.iam_mapping
  dlp_service_account = var.dlp_service_account
  tagger_role = var.tagger_role
  sa_tagging_dispatcher = var.sa_tagging_dispatcher
  sa_tagging_dispatcher_tasks = var.sa_tagging_dispatcher_tasks
  bq_results_dataset          = module.bigquery.results_dataset
}

module "cloud-run-tagging-dispatcher" {
  source                        = "../../modules/cloud-run"
  project                       = var.project
  region                        = var.compute_region
  service_image                 = var.dispatcher_service_image
  service_name                  = var.dispatcher_service_name
  service_account_email         = module.iam.sa_tagging_dispatcher_email
  invoker_service_account_email = module.iam.sa_tagging_dispatcher_tasks_email
  default_labels                = var.default_labels
  # Dispatcher could take time to list large number of tables
  timeout_seconds               = var.dispatcher_service_timeout_seconds
  max_containers                = 1
  max_cpu                       = 2
  environment_variables         = [
    {
      name  = "TAGGER_TOPIC",
      value = module.pubsub-tagger.topic-name,
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
      value = var.gcs_flags_bucket_name,
    },
    {
      name  = "SOLUTION_DATASET",
      value = module.bigquery.results_dataset,
    },
    {
      name  = "DLP_TABLE_STANDARD",
      value = module.bigquery.results_table_standard_dlp,
    },
    {
      name  = "DLP_TABLE_AUTO",
      value = local.auto_dlp_results_latest_view,
    },
    {
      name  = "IS_AUTO_DLP_MODE",
      value = tostring(var.is_auto_dlp_mode),
    },
    {
      name  = "LOGGING_TABLE",
      value = module.bigquery.logging_table
    },
    {
    name = "DLP_INSPECTION_TEMPLATES_IDS",
    value = jsonencode(local.created_dlp_inspection_templates),
    },
  ]
}

module "cloud-run-tagger" {
  source                        = "../../modules/cloud-run"
  project                       = var.project
  region                        = var.compute_region
  service_image                 = var.tagger_service_image
  service_name                  = var.tagger_service_name
  service_account_email         = module.iam.sa_tagger_email
  invoker_service_account_email = module.iam.sa_tagger_tasks_email
  default_labels                = var.default_labels
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
      value = var.gcs_flags_bucket_name,
    },
    {
      name  = "DLP_DATASET",
      value = module.bigquery.results_dataset,
    },
    {
      name  = "DLP_TABLE_STANDARD",
      value = module.bigquery.results_table_standard_dlp,
    },
    {
      name  = "DLP_TABLE_AUTO",
      value = local.auto_dlp_results_latest_view,
    },
    {
      name  = "VIEW_INFOTYPE_POLICYTAGS_MAP",
      value = module.bigquery.config_view_infotype_policytag_map
    },
    {
      name  = "VIEW_DATASET_DOMAIN_MAP",
      value = module.bigquery.config_view_dataset_domain_map
    },
    {
      name  = "VIEW_PROJECT_DOMAIN_MAP",
      value = module.bigquery.config_view_project_domain_map
    },
    {
      name  = "PROMOTE_MIXED_TYPES",
      value = tostring(var.promote_mixed_info_types),
    },
    {
      name  = "IS_AUTO_DLP_MODE",
      value = tostring(var.is_auto_dlp_mode),
    },
    {
      name  = "INFO_TYPE_MAP",
      value = jsonencode(local.info_types_map),
    }
  ]
}


// PubSub

module "pubsub-tagging-dispatcher" {
  source                                  = "../../modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = module.cloud-run-tagging-dispatcher.service_endpoint
  subscription_name                       = var.dispatcher_pubsub_sub
  subscription_service_account            = module.iam.sa_tagging_dispatcher_tasks_email
  topic                                   = var.dispatcher_pubsub_topic
  topic_publishers_sa_emails              = [var.cloud_scheduler_account]
  # use a deadline large enough to process BQ listing for large scopes
  subscription_ack_deadline_seconds       = var.dispatcher_subscription_ack_deadline_seconds
  # avoid resending dispatcher messages if things went wrong and the msg was NAK (e.g. timeout expired, app error, etc)
  # min value must be at equal to the ack_deadline_seconds
  subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
  default_labels                          = var.default_labels

}

module "pubsub-tagger" {
  source                                  = "../../modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = module.cloud-run-tagger.service_endpoint
  subscription_name                       = var.tagger_pubsub_sub
  subscription_service_account            = module.iam.sa_tagger_tasks_email
  topic                                   = var.tagger_pubsub_topic
  // Tagging Dispatcher and DLP service account must be able to publish messages to the Tagger
  topic_publishers_sa_emails              = [module.iam.sa_tagging_dispatcher_email, var.dlp_service_account]
  # Tagger is using BigQuery queries in BATCH mode to avoid INTERACTIVE query concurency limits and they might take longer time to execute under heavy load
  # 10m is max allowed
  subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  # How long to retain unacknowledged messages in the subscription's backlog, from the moment a message is published.
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions
  subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
  default_labels                          = var.default_labels
}