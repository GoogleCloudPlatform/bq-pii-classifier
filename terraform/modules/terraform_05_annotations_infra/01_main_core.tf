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

### Locals ####

locals {

  info_types_map = {
    for item in var.classification_taxonomy : item["info_type"] => {
      classification = item["classification"],
      labels         = item["labels"]
    }
  }
}

### LOGGING ####

resource "google_logging_project_sink" "bigquery-logging-sink" {
  name        = var.log_sink_name
  destination = "bigquery.googleapis.com/projects/${google_bigquery_dataset.logging_dataset.project}/datasets/${google_bigquery_dataset.logging_dataset.dataset_id}"
  filter      = "jsonPayload.global_app=bq-pii-classifier"
  # Use a unique writer (creates a unique service account used for writing)
  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = true
  }
}
#### Resources

### bucket to store xxl configurations that can't fit in env variables in Cloud Run
resource "google_storage_bucket" "gcs_solution_resources" {
  project = var.application_project
  name    = "${var.application_project}-resources"
  # This bucket is used by the services so let's create in the same compute region
  location = var.compute_region

  force_destroy = true

  uniform_bucket_level_access = true
}

### configs that are XXL to fit into a cloud run variable
resource "google_storage_bucket_object" "info_type_map_file" {
  name         = "INFO_TYPE_MAP.json"
  bucket       = google_storage_bucket.gcs_solution_resources.name
  content_type = "application/json"
  content      = jsonencode(local.info_types_map)
}





