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
  infotypes_policytags_map_select_statements = [for entry in local.created_policy_tags :
    "SELECT '${entry["region"]}' AS region, '${entry["domain"]}' AS domain, '${entry["classification"]}' AS classification, '${entry["info_type"]}' AS info_type, '${entry["policy_tag_id"]}' AS policy_tag"
  ]

  project_domain_map_select_statements = length(local.project_and_domains_filtered) == 0 ? ["SELECT CAST(NULL AS STRING) AS project, CAST(NULL AS STRING) AS domain"] : [for entry in local.project_and_domains_filtered :
    "SELECT '${entry["project"]}' AS project, '${entry["domain"]}' AS domain"
  ]

  dataset_domain_map_select_statements = length(local.datasets_and_domains_filtered) == 0 ? ["SELECT CAST(NULL AS STRING) AS project, CAST(NULL AS STRING) AS dataset, CAST(NULL AS STRING) AS domain"] : [for entry in local.datasets_and_domains_filtered :
    "SELECT '${entry["project"]}' AS project, '${entry["dataset"]}' AS dataset, '${entry["domain"]}' AS domain"
  ]
}


### BQ Monitoring Views ##################################################

resource "google_bigquery_table" "logging_view_tag_history" {
  project    = var.publishing_project
  dataset_id = var.logging_dataset_name
  table_id   = "v_log_tag_history"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/stacks/bq_discovery_stack/views/v_log_tag_history.tpl",
      {
        project       = var.publishing_project
        dataset       = var.logging_dataset_name
        logging_table = var.logging_table_name
      }
    )
  }
}

resource "google_bigquery_table" "logging_view_label_history" {
  project    = var.publishing_project
  dataset_id = var.logging_dataset_name
  table_id   = "v_log_label_history"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/stacks/bq_discovery_stack/views/v_log_label_history.tpl",
      {
        project       = var.publishing_project
        dataset       = var.logging_dataset_name
        logging_table = var.logging_table_name
      }
    )
  }
}


resource "google_bigquery_table" "view_tagging_actions" {
  project    = var.publishing_project
  dataset_id = var.logging_dataset_name
  table_id   = "v_tagging_actions"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/stacks/bq_discovery_stack/views/v_tagging_actions.tpl",
      {
        project                           = var.publishing_project
        dataset                           = var.logging_dataset_name
        v_log_tag_history                 = google_bigquery_table.logging_view_tag_history.table_id
        v_config_infotypes_policytags_map = google_bigquery_table.config_view_infotypes_policytags_map.table_id
      }
    )
  }
}


resource "google_bigquery_table" "view_run_summary_counts" {
  project    = var.publishing_project
  dataset_id = var.logging_dataset_name
  table_id   = "v_run_summary_counts"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/stacks/bq_discovery_stack/views/v_run_summary_counts.tpl",
      {
        project                  = var.publishing_project
        dataset                  = var.logging_dataset_name
        v_run_summary            = var.bq_view_run_summary
        dispatcher_runs_bigquery = google_bigquery_table.dispatcher_runs_bq_table.table_id
      }
    )
  }
}


resource "google_bigquery_table" "config_view_infotypes_policytags_map" {
  project    = var.publishing_project
  dataset_id = var.logging_dataset_name
  table_id   = "v_config_infotypes_policytags_map"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query          = join(" UNION ALL \r\n", local.infotypes_policytags_map_select_statements)
  }
}

resource "google_bigquery_table" "config_view_project_domain_map" {
  project    = var.publishing_project
  dataset_id = var.logging_dataset_name
  table_id   = "v_config_projects_domains_map"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query          = join(" UNION ALL \r\n", local.project_domain_map_select_statements)
  }
}

resource "google_bigquery_table" "config_view_dataset_domain_map" {
  project    = var.publishing_project
  dataset_id = var.logging_dataset_name
  table_id   = "v_config_datasets_domains_map"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query          = join(" UNION ALL \r\n", local.dataset_domain_map_select_statements)
  }
}

resource "google_bigquery_table" "dispatcher_runs_bq_table" {

  project    = var.publishing_project
  dataset_id = var.logging_dataset_name
  table_id   = "dispatcher_runs_bigquery"

  clustering = ["run_id"]

  schema = file("../../modules/terraform_05_annotations_infra/stacks/bq_discovery_stack/schema/dispatcher_runs_bigquery.json")

  deletion_protection = var.terraform_data_deletion_protection
}