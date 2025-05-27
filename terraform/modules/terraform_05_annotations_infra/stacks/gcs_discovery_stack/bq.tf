resource "google_bigquery_table" "view_gcs_run_summary_counts_gcs" {
  project = var.publishing_project
  dataset_id = var.dlp_dataset_name
  table_id = "v_run_summary_counts_gcs"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/stacks/gcs_discovery_stack/views/v_run_summary_counts_gcs.tpl",
      {
        project = var.publishing_project
        dataset = var.dlp_dataset_name
        v_run_summary = var.bq_view_run_summary
        dispatcher_runs_gcs = google_bigquery_table.dispatcher_runs_gcs_table.table_id
      }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "logging_view_label_history_gcs" {
  project = var.publishing_project
  dataset_id = var.dlp_dataset_name
  table_id = "v_log_label_history_gcs"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/stacks/gcs_discovery_stack/views/v_log_label_history_gcs.tpl",
      {
        project = var.publishing_project
        dataset = var.dlp_dataset_name
        logging_table = var.logging_table_name
      }
    )
  }
  labels = var.default_labels
}

resource "google_bigquery_table" "dispatcher_runs_gcs_table" {

  project = var.publishing_project
  dataset_id = var.dlp_dataset_name
  table_id = "dispatcher_runs_gcs"

  clustering = ["run_id"]

  schema = file("../../modules/terraform_05_annotations_infra/stacks/gcs_discovery_stack/schema/dispatcher_runs_gcs.json")

  deletion_protection = var.terraform_data_deletion_protection

  labels = var.default_labels
}