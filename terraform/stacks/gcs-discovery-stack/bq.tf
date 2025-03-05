resource "google_bigquery_table" "view_gcs_run_summary_counts_gcs" {
  dataset_id = var.bq_results_dataset
  table_id = "v_run_summary_counts_gcs"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("stacks/gcs-discovery-stack/views/v_run_summary_counts_gcs.tpl",
      {
        project = var.project
        dataset = var.bq_results_dataset
        v_run_summary = var.bq_view_run_summary
        dispatcher_runs_gcs = google_bigquery_table.dispatcher_runs_gcs_table.table_id
      }
    )
  }
}


resource "google_bigquery_table" "logging_view_label_history_gcs" {
  dataset_id = var.bq_results_dataset
  table_id = "v_log_label_history_gcs"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("stacks/gcs-discovery-stack/views/v_log_label_history_gcs.tpl",
      {
        project = var.project
        dataset = var.bq_results_dataset
        logging_table = var.logging_table_name
      }
    )
  }
}

resource "google_bigquery_table" "dispatcher_runs_gcs_table" {

  project = var.project
  dataset_id = var.bq_results_dataset
  table_id = "dispatcher_runs_gcs"

  clustering = ["run_id"]

  schema = file("stacks/gcs-discovery-stack/schema/dispatcher_runs_gcs.json")

  deletion_protection = var.terraform_data_deletion_protection
}