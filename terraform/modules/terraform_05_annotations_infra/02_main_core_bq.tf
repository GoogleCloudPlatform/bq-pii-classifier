#######################################################################################################################
#                                    BigQuery
#######################################################################################################################


#############################################################
#                                    Dataset & Permissions
##############################################################

resource "google_bigquery_dataset" "logging_dataset" {
  project = var.publishing_project
  location = var.data_region
  dataset_id = var.bigquery_dataset_name
  description = "To store logs and monitoring views for the GCP data annotations solution"

  delete_contents_on_destroy = !var.terraform_data_deletion_protection

  labels = var.default_labels
}


#############################################################
#                                    Tables
##############################################################

resource "google_bigquery_table" "logging_table_cloud_run" {
  project = var.publishing_project
  dataset_id = google_bigquery_dataset.logging_dataset.dataset_id
  # don't change the name so that cloud logging can find it
  table_id = "run_googleapis_com_stdout"

  time_partitioning {
    type = "DAY"
    #expiration_ms = 604800000 # 7 days
  }

  schema = file("../../modules/terraform_05_annotations_infra/schema/cloud_logging_export.json")

  deletion_protection = var.terraform_data_deletion_protection

  labels = var.default_labels
}

resource "google_bigquery_table" "logging_table_cloud_batch" {
  project = var.publishing_project
  dataset_id = google_bigquery_dataset.logging_dataset.dataset_id
  # don't change the name so that cloud logging can find it
  table_id = "batch_task_logs"

  time_partitioning {
    type = "DAY"
    #expiration_ms = 604800000 # 7 days
  }

  schema = file("../../modules/terraform_05_annotations_infra/schema/cloud_logging_export.json")

  deletion_protection = var.terraform_data_deletion_protection

  labels = var.default_labels
}

#############################################################
#                                    Views
##############################################################

resource "google_bigquery_table" "logging_view_steps" {
  project = var.publishing_project
  dataset_id = google_bigquery_dataset.logging_dataset.dataset_id
  table_id = "v_steps"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/views/v_steps.tpl",
      {
        project = var.publishing_project
        dataset = google_bigquery_dataset.logging_dataset.dataset_id
        logging_table = google_bigquery_table.logging_table_cloud_run.table_id
      }
    )
  }

  labels = var.default_labels
}

resource "google_bigquery_table" "view_service_calls" {
  project = var.publishing_project
  dataset_id = google_bigquery_dataset.logging_dataset.dataset_id
  table_id = "v_service_calls"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/views/v_service_calls.tpl",
      {
        project = var.publishing_project
        dataset = google_bigquery_dataset.logging_dataset.dataset_id
        logging_view_steps = google_bigquery_table.logging_view_steps.table_id
      }
    )
  }

  labels = var.default_labels
}

resource "google_bigquery_table" "logging_view_broken_steps" {
  project = var.publishing_project
  dataset_id = google_bigquery_dataset.logging_dataset.dataset_id
  table_id = "v_broken_steps"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/views/v_broken_steps.tpl",
      {
        project = var.publishing_project
        dataset = google_bigquery_dataset.logging_dataset.dataset_id
        v_service_calls = google_bigquery_table.view_service_calls.table_id
        logging_table = google_bigquery_table.logging_table_cloud_run.table_id
      }
    )
  }

  labels = var.default_labels
}


resource "google_bigquery_table" "view_errors_non_retryable" {
  project = var.publishing_project
  dataset_id = google_bigquery_dataset.logging_dataset.dataset_id
  table_id = "v_errors_non_retryable"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/views/v_errors_non_retryable.tpl",
      {
        project = var.publishing_project
        dataset = google_bigquery_dataset.logging_dataset.dataset_id
        logging_table = google_bigquery_table.logging_table_cloud_run.table_id
      }
    )
  }

  labels = var.default_labels
}

resource "google_bigquery_table" "view_errors_retryable" {
  project = var.publishing_project
  dataset_id = google_bigquery_dataset.logging_dataset.dataset_id
  table_id = "v_errors_retryable"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/views/v_errors_retryable.tpl",
      {
        project = var.publishing_project
        dataset = google_bigquery_dataset.logging_dataset.dataset_id
        logging_table = google_bigquery_table.logging_table_cloud_run.table_id
      }
    )
  }

  labels = var.default_labels
}

resource "google_bigquery_table" "view_run_summary" {
  project = var.publishing_project
  dataset_id = var.bigquery_dataset_name
  table_id = "v_run_summary"

  deletion_protection = var.terraform_data_deletion_protection

  view {
    use_legacy_sql = false
    query = templatefile("../../modules/terraform_05_annotations_infra/views/v_run_summary.tpl",
      {
        project = var.publishing_project
        dataset = var.bigquery_dataset_name
        v_service_calls = google_bigquery_table.view_service_calls.table_id
        v_errors_non_retryable = google_bigquery_table.view_errors_non_retryable.table_id
      }
    )
  }

  labels = var.default_labels
}

