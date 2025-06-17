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

resource "google_bigquery_table" "view_gcs_run_summary_counts_gcs" {
  project    = var.publishing_project
  dataset_id = var.logging_dataset_name
  table_id   = "v_run_summary_counts_gcs"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/stacks/gcs_discovery_stack/views/v_run_summary_counts_gcs.tpl",
      {
        project             = var.publishing_project
        dataset             = var.logging_dataset_name
        v_run_summary       = var.bq_view_run_summary
        dispatcher_runs_gcs = google_bigquery_table.dispatcher_runs_gcs_table.table_id
      }
    )
  }
}

resource "google_bigquery_table" "logging_view_label_history_gcs" {
  project    = var.publishing_project
  dataset_id = var.logging_dataset_name
  table_id   = "v_log_label_history_gcs"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/stacks/gcs_discovery_stack/views/v_log_label_history_gcs.tpl",
      {
        project       = var.publishing_project
        dataset       = var.logging_dataset_name
        logging_table = var.logging_table_name
      }
    )
  }
}

resource "google_bigquery_table" "dispatcher_runs_gcs_table" {

  project    = var.publishing_project
  dataset_id = var.logging_dataset_name
  table_id   = "dispatcher_runs_gcs"

  clustering = ["run_id"]

  schema = file("../../modules/terraform_05_annotations_infra/stacks/gcs_discovery_stack/schema/dispatcher_runs_gcs.json")

  deletion_protection = var.terraform_data_deletion_protection
}