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

  disable_on_destroy         = false
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

  disable_on_destroy         = false
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
    project = lookup(entry, "project"),
    domain = lookup(entry, "domain")
  }
  ])

  # Only projects with configured domains
  project_and_domains_filtered = [for entry in local.project_and_domains: entry if lookup(entry, "domain") != ""]

  datasets_and_domains = distinct(flatten([
  for entry in var.domain_mapping : [
  for dataset in lookup(entry, "datasets", []) : {
    project = lookup(entry, "project"),
    dataset = lookup(dataset, "name"),
    domain = lookup(dataset, "domain")
  }
  ]]))

  # Only datasets with configured domains
  datasets_and_domains_filtered = [for entry in local.datasets_and_domains: entry if lookup(entry, "domain") != ""]

  # Get distinct domains set on project entries
  project_domains = distinct([
  for entry in local.project_and_domains_filtered : lookup(entry, "domain")
  ])

  # Get distinct domains set on dataset level
  dataset_domains = distinct([
  for entry in local.datasets_and_domains_filtered : lookup(entry, "domain")
  ])

  // Concat project and dataset domains and filter out empty strings
  domains = distinct(concat(local.project_domains, local.dataset_domains))

  # comma separated string with taxonomy names
  created_taxonomies = join(",", [for taxonomy in module.data-catalog[*].created_taxonomy: taxonomy.name])

  // one list of all policy tags generated across domain taxonomies
  // each element of the list is a map with three attributes (policy_tag_id, domain, info_type)
  created_policy_tags = flatten(module.data-catalog[*].created_children_tags)

  created_parent_tags = flatten(module.data-catalog[*].created_parent_tags)

  timestamp = formatdate("YYMMDDhhmmss", timestamp())
}

module "data-catalog" {
  count = length(local.domains)
  source = "../../modules/data-catalog"
  project = var.project
  region = var.data_region
  domain = local.domains[count.index]
  nodes = var.classification_taxonomy
}


module "bigquery" {
  source = "../../modules/bigquery"
  project = var.project
  region = var.data_region
  dataset = "${var.bigquery_dataset_name}_${var.env}"
  logging_sink_sa = module.cloud_logging.service_account

  # Data for config views
  created_policy_tags = local.created_policy_tags
  dataset_domains_mapping = local.datasets_and_domains_filtered
  projects_domains_mapping = local.project_and_domains_filtered
  dlp_findings_view_template_name = var.dlp_findings_view_template_name
  is_auto_dlp_mode = var.is_auto_dlp_mode
  auto_dlp_results_table_name = var.auto_dlp_results_table_name
  standard_dlp_results_table_name = var.standard_dlp_results_table_name
}

module "cloud_logging" {
  source = "../../modules/cloud-logging"

  dataset = module.bigquery.results_dataset
  project = var.project
  region = var.compute_region
  log_sink_name = "${var.log_sink_name}_${var.env}"
}

// DLP
module "dlp" {
  source = "../../modules/dlp"
  project = var.project
  region = var.data_region # create inspection template in the same region as data
  classification_taxonomy = var.classification_taxonomy
}

module "cloud_scheduler" {
  source = "../../modules/cloud-scheduler"
  project = var.project
  region = var.compute_region
  scheduler_name = "${var.scheduler_name}-${var.env}"

  target_uri = module.pubsub-tagging-dispatcher.topic-id

  tables_include_list = var.tables_include_list
  datasets_include_list = var.datasets_include_list
  projects_include_list = var.projects_include_list
  datasets_exclude_list = var.datasets_exclude_list
  tables_exclude_list = var.tables_exclude_list
  cron_expression = var.cron_expression

  depends_on = [google_project_service.enable_appengine]
}

module "iam" {
  source = "../../modules/iam"
  project = var.project
  region = var.compute_region
  sa_tagger = "${var.sa_tagger}-${var.env}"
  sa_tagger_tasks = "${var.sa_tagger_tasks}-${var.env}"
  taxonomy_parent_tags = local.created_parent_tags
  iam_mapping = var.iam_mapping
  dlp_service_account = var.dlp_service_account
  tagger_role = "${var.tagger_role}_${var.env}"
  sa_tagging_dispatcher = "${var.sa_tagging_dispatcher}-${var.env}"
  sa_tagging_dispatcher_tasks = "${var.sa_tagging_dispatcher_tasks}-${var.env}"
  bq_results_dataset = module.bigquery.results_dataset
}

module "cloud-run-tagging-dispatcher" {
  source = "../../modules/cloud-run"
  project = var.project
  region = var.compute_region
  service_image = var.dispatcher_service_image
  service_name = "${var.dispatcher_service_name}-${var.env}"
  service_account_email = module.iam.sa_tagging_dispatcher_email
  invoker_service_account_email = module.iam.sa_tagging_dispatcher_tasks_email
  environment_variables =  [
    {
      name = "BQ_VIEW_FIELDS_FINDINGS_SPEC",
      value = module.bigquery.bq_view_dlp_fields_findings,
    },
    {
      name = "TAGGER_TOPIC",
      value = module.pubsub-tagger.topic-name,
    },
    {
      name = "COMPUTE_REGION_ID",
      value = var.compute_region,
    },
    {
      name = "DATA_REGION_ID",
      value = var.data_region,
    },
    {
      name = "PROJECT_ID",
      value = var.project,
    },
    ]
}

module "cloud-run-tagger" {
  source = "../../modules/cloud-run"
  project = var.project
  region = var.compute_region
  service_image = var.tagger_service_image
  service_name = "${var.tagger_service_name}-${var.env}"
  service_account_email = module.iam.sa_tagger_email
  invoker_service_account_email = module.iam.sa_tagger_tasks_email
  environment_variables =  [
    {
      name = "BQ_VIEW_FIELDS_FINDINGS_SPEC",
      value = module.bigquery.bq_view_dlp_fields_findings,
    },
    {
      name = "IS_DRY_RUN",
      value = var.is_dry_run,
    },
    {
      name = "TAXONOMIES",
      value = local.created_taxonomies,
    },
    {
      name = "REGION_ID",
      value = var.compute_region,
    },
    {
      name = "PROJECT_ID",
      value = var.project,
    },
  ]
}


// PubSub

module "pubsub-tagging-dispatcher" {
  source = "../../modules/pubsub"
  project = var.project
  subscription_endpoint = module.cloud-run-tagging-dispatcher.service_endpoint
  subscription_name = "${var.dispatcher_pubsub_sub}_${var.env}"
  subscription_service_account = module.iam.sa_tagging_dispatcher_tasks_email
  topic = "${var.dispatcher_pubsub_topic}_${var.env}"
  topic_publisher_sa_email = var.cloud_scheduler_account
}

module "pubsub-tagger" {
  source = "../../modules/pubsub"
  project = var.project
  subscription_endpoint = module.cloud-run-tagger.service_endpoint
  subscription_name = "${var.tagger_pubsub_sub}_${var.env}"
  subscription_service_account = module.iam.sa_tagger_tasks_email
  topic = "${var.tagger_pubsub_topic}_${var.env}"
  topic_publisher_sa_email = module.iam.sa_tagging_dispatcher_email
}







