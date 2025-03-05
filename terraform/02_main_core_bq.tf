### BigQuery ####

resource "google_bigquery_dataset" "results_dataset" {
  project = var.project
  location = var.data_region
  dataset_id = var.bigquery_dataset_name
  description = "To store DLP results and data for the BQ PII Classifier solution"

  delete_contents_on_destroy = !var.terraform_data_deletion_protection

  depends_on = [google_project_service.enable_apis]
}

# Logging BQ sink must be able to write data to logging table in the dataset
resource "google_bigquery_dataset_iam_member" "logging_sink_access" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  role = "roles/bigquery.dataEditor"
  member = google_logging_project_sink.bigquery-logging-sink.writer_identity
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

  schema = file("schema/run_googleapis_com_stdout.json")

  deletion_protection = var.terraform_data_deletion_protection
}


resource "google_bigquery_table" "logging_view_steps" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_steps"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("views/v_steps.tpl",
      {
        project = var.project
        dataset = google_bigquery_dataset.results_dataset.dataset_id
        logging_table = google_bigquery_table.logging_table.table_id
      }
    )
  }
}

resource "google_bigquery_table" "view_service_calls" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_service_calls"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("views/v_service_calls.tpl",
      {
        project = var.project
        dataset = google_bigquery_dataset.results_dataset.dataset_id
        logging_view_steps = google_bigquery_table.logging_view_steps.table_id
      }
    )
  }
}

resource "google_bigquery_table" "logging_view_broken_steps" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_broken_steps"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("views/v_broken_steps.tpl",
      {
        project = var.project
        dataset = google_bigquery_dataset.results_dataset.dataset_id
        v_service_calls = google_bigquery_table.view_service_calls.table_id
        logging_table = google_bigquery_table.logging_table.table_id
        inspection_templates_count = local.inspection_templates_count
      }
    )
  }
}


resource "google_bigquery_table" "view_errors_non_retryable" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_errors_non_retryable"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("views/v_errors_non_retryable.tpl",
      {
        project = var.project
        dataset = google_bigquery_dataset.results_dataset.dataset_id
        logging_table = google_bigquery_table.logging_table.table_id
      }
    )
  }
}

resource "google_bigquery_table" "view_errors_retryable" {
  dataset_id = google_bigquery_dataset.results_dataset.dataset_id
  table_id = "v_errors_retryable"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("views/v_errors_retryable.tpl",
      {
        project = var.project
        dataset = google_bigquery_dataset.results_dataset.dataset_id
        logging_table = google_bigquery_table.logging_table.table_id
      }
    )
  }
}

resource "google_bigquery_table" "view_run_summary" {
  dataset_id = var.bigquery_dataset_name
  table_id = "v_run_summary"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("views/v_run_summary.tpl",
      {
        project = var.project
        dataset = var.bigquery_dataset_name
        v_service_calls = google_bigquery_table.view_service_calls.table_id
        v_errors_non_retryable = google_bigquery_table.view_errors_non_retryable.table_id
        inspection_templates_count = local.inspection_templates_count
      }
    )
  }
}

