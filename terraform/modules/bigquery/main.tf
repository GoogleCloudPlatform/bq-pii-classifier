# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset


######## Datasets ##############################################################

resource "google_bigquery_dataset" "results_dataset" {
  project = var.project
  location = var.region
  dataset_id = var.dataset
  description = "To store DLP results from BQ PII Classifier solution"
  # contents have deletion_protection set according to user configuration
  delete_contents_on_destroy = true
  labels = var.default_labels
}

# Logging BQ sink must be able to write data to logging table in the dataset
resource "google_bigquery_dataset_iam_member" "logging_sink_access" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  role = "roles/bigquery.dataEditor"
  member = var.logging_sink_sa
}

##### Tables #######################################################

resource "google_bigquery_table" "standard_dlp_results_table" {

  #count = var.is_auto_dlp_mode ? 0 : 1

  project = var.project
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = var.standard_dlp_results_table_name

  # ingestion time partitioning
  time_partitioning {
    type = "DAY"
  }

  # use job_name as a cluster to limit the number of bytes scanned to lookup job results
  clustering = ["job_name"]

  schema = file("modules/bigquery/schema/standard_dlp_results.json")

  deletion_protection = var.terraform_data_deletion_protection
  labels = var.default_labels
}

resource "google_bigquery_table" "logging_table" {
  project = var.project
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  # don't change the name so that cloud logging can find it
  table_id = "run_googleapis_com_stdout"

  time_partitioning {
    type = "DAY"
    #expiration_ms = 604800000 # 7 days
  }

  schema = file("modules/bigquery/schema/run_googleapis_com_stdout.json")

  deletion_protection = var.terraform_data_deletion_protection
  labels = var.default_labels
}


### Monitoring Views ##################################################

resource "google_bigquery_table" "logging_view_tag_history" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_log_tag_history"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_log_tag_history.tpl",
    {
      project = var.project
      dataset = var.dataset
      logging_table = google_bigquery_table.logging_table.table_id
    }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "logging_view_label_history" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_log_label_history"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_log_label_history.tpl",
      {
        project = var.project
        dataset = var.dataset
        logging_table = google_bigquery_table.logging_table.table_id
      }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "logging_view_steps" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_steps"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_steps.tpl",
    {
      project = var.project
      dataset = var.dataset
      logging_table = google_bigquery_table.logging_table.table_id
    }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "view_service_calls" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_service_calls"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_service_calls.tpl",
    {
      project = var.project
      dataset = var.dataset
      logging_view_steps = google_bigquery_table.logging_view_steps.table_id
    }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "logging_view_broken_steps" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_broken_steps"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_broken_steps.tpl",
    {
      project = var.project
      dataset = var.dataset
      v_service_calls = google_bigquery_table.view_service_calls.table_id
      logging_table = google_bigquery_table.logging_table.table_id
      inspection_templates_count = var.inspection_templates_count
    }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "view_tagging_actions" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_tagging_actions"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_tagging_actions.tpl",
    {
      project = var.project
      dataset = var.dataset
      v_log_tag_history = google_bigquery_table.logging_view_tag_history.table_id
      v_config_infotypes_policytags_map = google_bigquery_table.config_view_infotypes_policytags_map.table_id
    }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "view_run_summary" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_run_summary"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_run_summary.tpl",
    {
      project = var.project
      dataset = var.dataset
      v_service_calls = google_bigquery_table.view_service_calls.table_id
      v_errors_non_retryable = google_bigquery_table.view_errors_non_retryable.table_id
      inspection_templates_count = var.inspection_templates_count
    }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "view_run_summary_counts" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_run_summary_counts"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_run_summary_counts.tpl",
    {
      project = var.project
      dataset = var.dataset
      v_run_summary = google_bigquery_table.view_run_summary.table_id
      logging_table = google_bigquery_table.logging_table.table_id
    }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "view_errors_non_retryable" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_errors_non_retryable"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_errors_non_retryable.tpl",
    {
      project = var.project
      dataset = var.dataset
      logging_table = google_bigquery_table.logging_table.table_id
    }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "view_errors_retryable" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_errors_retryable"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_errors_retryable.tpl",
    {
      project = var.project
      dataset = var.dataset
      logging_table = google_bigquery_table.logging_table.table_id
    }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "view_tracking_id_map" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_tracking_id_to_table_map"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_tracking_id_to_table_map.tpl",
    {
      project = var.project
      dataset = var.dataset
      logging_table = google_bigquery_table.logging_table.table_id
    }
    )
  }
  labels = var.default_labels
}

######## CONFIG VIEWS #####################################################################

locals {
  infotypes_policytags_map_select_statements = [for entry in var.created_policy_tags:
  "SELECT '${entry["region"]}' AS region, '${entry["domain"]}' AS domain, '${entry["classification"]}' AS classification, '${entry["info_type"]}' AS info_type, '${entry["policy_tag_id"]}' AS policy_tag"
  ]

  project_domain_map_select_statements = [for entry in var.projects_domains_mapping:
  "SELECT '${entry["project"]}' AS project, '${entry["domain"]}' AS domain"
  ]

  dataset_domain_map_select_statements = length(var.dataset_domains_mapping) == 0 ? ["SELECT '' AS project, '' AS dataset, '' AS domain"] :[for entry in var.dataset_domains_mapping:
  "SELECT '${entry["project"]}' AS project, '${entry["dataset"]}' AS dataset, '${entry["domain"]}' AS domain"
  ]
}

resource "google_bigquery_table" "config_view_infotypes_policytags_map" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_config_infotypes_policytags_map"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = join(" UNION ALL \r\n", local.infotypes_policytags_map_select_statements)
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "config_view_project_domain_map" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_config_projects_domains_map"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = join(" UNION ALL \r\n", local.project_domain_map_select_statements)
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "config_view_dataset_domain_map" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_config_datasets_domains_map"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = join(" UNION ALL \r\n", local.dataset_domain_map_select_statements)
  }
  labels = var.default_labels
}

