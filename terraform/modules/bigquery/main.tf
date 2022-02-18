# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset


locals {

  // We only create a dlp results table if we're in standard mode.
  // For AutoDLP mode, we expect the table to be created and it's spec/name passed to the module to be used in the view
  results_table_spec = var.is_auto_dlp_mode ? "${var.project}.${var.dataset}.${google_bigquery_table.auto_dlp_results_table.table_id}" : "${var.project}.${var.dataset}.${google_bigquery_table.standard_dlp_results_table.table_id}"
}

######## Datasets ##############################################################

resource "google_bigquery_dataset" "results_dataset" {
  project = var.project
  location = var.region
  dataset_id = var.dataset
  description = "To store DLP results from BQ Security Classifier app"
}

# Logging BQ sink must be able to write data to logging table in the dataset
resource "google_bigquery_dataset_iam_member" "logging_sink_access" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  role = "roles/bigquery.dataEditor"
  member = var.logging_sink_sa
}

##### Tables #######################################################

resource "google_bigquery_table" "auto_dlp_results_table" {

  #count = var.is_auto_dlp_mode ? 1 : 0

  project = var.project
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = var.auto_dlp_results_table_name

  schema = file("modules/bigquery/schema/auto_dlp_results.json")

  deletion_protection = true
}

resource "google_bigquery_table" "standard_dlp_results_table" {

  #count = var.is_auto_dlp_mode ? 0 : 1

  project = var.project
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = var.standard_dlp_results_table_name

  schema = file("modules/bigquery/schema/standard_dlp_results.json")

  deletion_protection = true
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

  deletion_protection = true
}


### Monitoring Views ##################################################

resource "google_bigquery_table" "logging_view_tag_history" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_log_tag_history"

  deletion_protection = false

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
}


resource "google_bigquery_table" "logging_view_steps" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_steps"

  deletion_protection = false

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
}

resource "google_bigquery_table" "view_service_calls" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_service_calls"

  deletion_protection = false

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
}

resource "google_bigquery_table" "logging_view_broken_steps" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_broken_steps"

  deletion_protection = false

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_broken_steps.tpl",
    {
      project = var.project
      dataset = var.dataset
      v_service_calls = google_bigquery_table.view_service_calls.table_id
      logging_table = google_bigquery_table.logging_table.table_id
    }
    )
  }
}

resource "google_bigquery_table" "view_fields_findings" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_dlp_fields_findings"

  deletion_protection = false

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/${var.dlp_findings_view_template_name}.tpl",
    {
      project = var.project
      dataset = var.dataset
      config_view_infotypes_policytags_map = google_bigquery_table.config_view_infotypes_policytags_map.table_id
      config_view_dataset_domain_map = google_bigquery_table.config_view_dataset_domain_map.table_id
      config_view_project_domain_map = google_bigquery_table.config_view_project_domain_map.table_id
      results_table_spec = local.results_table_spec
    }
    )
  }
}

resource "google_bigquery_table" "view_tagging_actions" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_tagging_actions"

  deletion_protection = false

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
}

resource "google_bigquery_table" "view_run_summary" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_run_summary"

  deletion_protection = false

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_run_summary.tpl",
    {
      project = var.project
      dataset = var.dataset
      v_tagging_actions = google_bigquery_table.view_tagging_actions.table_id
      v_broken_steps = google_bigquery_table.logging_view_broken_steps.table_id
    }
    )
  }
}

resource "google_bigquery_table" "view_run_summary_counts" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_run_summary_counts"

  deletion_protection = false

  view {
    use_legacy_sql = false
    query = templatefile("modules/bigquery/views/v_run_summary_counts.tpl",
    {
      project = var.project
      dataset = var.dataset
      v_run_summary = google_bigquery_table.view_run_summary.table_id
    }
    )
  }
}

resource "google_bigquery_table" "view_errors_non_retryable" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_errors_non_retryable"

  deletion_protection = false

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
}

resource "google_bigquery_table" "view_errors_retryable" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_errors_retryable"

  deletion_protection = false

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
}

resource "google_bigquery_table" "view_tracking_id_map" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_tracking_id_to_table_map"

  deletion_protection = false

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
}

######## CONFIG VIEWS #####################################################################

locals {
  infotypes_policytags_map_select_statements = [for entry in var.created_policy_tags:
  "SELECT '${lookup(entry,"domain","NA")}' AS domain, '${lookup(entry,"info_type","NA")}' AS info_type, '${lookup(entry,"policy_tag_id","NA")}' AS policy_tag"
  ]

  project_domain_map_select_statements = [for entry in var.projects_domains_mapping:
  "SELECT '${lookup(entry,"project")}' AS project, '${lookup(entry,"domain")}' AS domain"
  ]

  dataset_domain_map_select_statements = length(var.dataset_domains_mapping) == 0 ? ["SELECT '' AS project, '' AS dataset, '' AS domain"] :[for entry in var.dataset_domains_mapping:
  "SELECT '${lookup(entry,"project")}' AS project, '${lookup(entry,"dataset")}' AS dataset, '${lookup(entry,"domain")}' AS domain"
  ]
}

resource "google_bigquery_table" "config_view_infotypes_policytags_map" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_config_infotypes_policytags_map"

  #TODO:  Allow destroying the table. Set to true for production use
  deletion_protection = false

  view {
    use_legacy_sql = false
    query = join(" UNION ALL \r\n", local.infotypes_policytags_map_select_statements)
  }
}

resource "google_bigquery_table" "config_view_project_domain_map" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_config_projects_domains_map"

  deletion_protection = false

  view {
    use_legacy_sql = false
    query = join(" UNION ALL \r\n", local.project_domain_map_select_statements)
  }
}

resource "google_bigquery_table" "config_view_dataset_domain_map" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_config_datasets_domains_map"

  deletion_protection = false

  view {
    use_legacy_sql = false
    query = join(" UNION ALL \r\n", local.dataset_domain_map_select_statements)
  }
}

