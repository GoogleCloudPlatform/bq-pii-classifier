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
  impersonate_service_account = var.terraform_service_account_email
}

data google_project "gcp_project" {
  project_id = var.project
}

### Locals ####

locals {


  dlp_service_account_email = "service-${data.google_project.gcp_project.number}@dlp-api.iam.gserviceaccount.com"

  dlp_inspection_templates_ids_list = flatten([for obj in local.created_dlp_inspection_templates : obj["ids"]])

  inspection_templates_count = max([for x in var.classification_taxonomy : x["inspection_template_number"]]...)

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
  project  = var.project
  name     = "${var.project}-${var.gcs_flags_bucket_name}"
  # This bucket is used by the services so let's create in the same compute region
  location = var.compute_region

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

  depends_on = [google_project_service.enable_apis]
}

### LOGGING ####

resource "google_logging_project_sink" "bigquery-logging-sink" {
  name                   = var.log_sink_name
  destination            = "bigquery.googleapis.com/projects/${var.project}/datasets/${google_bigquery_dataset.results_dataset.dataset_id}"
  filter                 = "resource.type=cloud_run_revision jsonPayload.global_app=bq-pii-classifier"
  # Use a unique writer (creates a unique service account used for writing)
  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = true
  }

  depends_on = [google_project_service.enable_apis]
}

### DLP ####

# deploy 1 dlp inspection template in each source data region
locals {
  dlp_regions = var.deploy_dlp_inspection_template_to_global_region? concat(tolist(var.source_data_regions), [
    "global"
  ]) : var.source_data_regions
}

module "dlp" {
  count                   = length(local.dlp_regions)
  source                  = "./modules/dlp"
  project                 = var.project
  region                  = tolist(local.dlp_regions)[count.index]
  classification_taxonomy = var.classification_taxonomy
  custom_info_types_dictionaries = var.custom_info_types_dictionaries
  custom_info_types_regex        = var.custom_info_types_regex

  depends_on = [google_project_service.enable_apis]
}








