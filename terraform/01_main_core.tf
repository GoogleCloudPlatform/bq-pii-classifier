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

### Locals ####

locals {

  # is_auto_dlp_mode is a legacy variable that is removed as a variable but still being used as a config in other modules
  is_auto_dlp_mode = contains(var.supported_stacks, "BIGQUERY_DISCOVERY")

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

  dlp_inspection_templates_ids_list = flatten([for obj in local.created_dlp_inspection_templates : obj["ids"]])

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

### GCS RESOURCES ####

resource "google_storage_bucket" "gcs_flags_bucket" {
  project = var.project
  name          = "${var.project}-${var.gcs_flags_bucket_name}"
  # This bucket is used by the services so let's create in the same compute region
  location      = var.compute_region

  force_destroy = !var.terraform_data_deletion_protection

  lifecycle_rule {
    condition {
      # Clean up old flags to save storage and GCS operations overhead
      age = 3 # days
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true
}

### LOGGING ####

resource "google_logging_project_sink" "bigquery-logging-sink" {
  name = var.log_sink_name
  destination = "bigquery.googleapis.com/projects/${var.project}/datasets/${google_bigquery_dataset.results_dataset.dataset_id}"
  filter = "resource.type=cloud_run_revision jsonPayload.global_app=bq-pii-classifier"
  # Use a unique writer (creates a unique service account used for writing)
  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = true
  }
}

### DLP ####

# deploy 1 dlp inspection template in each source data region
module "dlp" {
  count = length(var.source_data_regions)
  source                  = "./modules/dlp"
  project                 = var.project
  region                  = tolist(var.source_data_regions)[count.index] # create inspection template in the same region as source data
  classification_taxonomy = var.classification_taxonomy

  custom_info_types_dictionaries = var.custom_info_types_dictionaries
  custom_info_types_regex        = var.custom_info_types_regex
}

