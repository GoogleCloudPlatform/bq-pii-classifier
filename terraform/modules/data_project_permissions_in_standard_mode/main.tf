
# Inspection Dispatcher needs to list datasets and tables in a project and know the location of datasets
resource "google_project_iam_member" "data_project_iam_inspection_dispatcher_bq_metadata_viewer" {
  project = var.target_project
  role = "roles/bigquery.metadataViewer"
  member = "serviceAccount:${var.sa_inspection_dispatcher_email}"
}

# Tagging Dispatcher needs to know the location of datasets
resource "google_project_iam_member" "data_project_iam_tagging_dispatcher_bq_metadata_viewer" {
  project = var.target_project
  role = "roles/bigquery.metadataViewer"
  member = "serviceAccount:${var.sa_tagging_dispatcher_email}"
}

# Inspector needs to view table's metadata (row count)
resource "google_project_iam_member" "data_project_iam_inspector_bq_metadata_viewer" {
  project = var.target_project
  role = "roles/bigquery.metadataViewer"
  member = "serviceAccount:${var.sa_inspector_email}"
}

# Tagger needs to read table schema and update tables policy tags
resource "google_project_iam_member" "data_project_tagger_bq_data_owner" {
  project = var.target_project
  role = "roles/bigquery.dataOwner"
  member = "serviceAccount:${var.sa_tagger_email}"
}

# DLP service account needs to read and inspect bigquery data
resource "google_project_iam_member" "data_project_dlp_bq_data_viewer" {
  project = var.target_project
  role = "roles/bigquery.dataViewer"
  member = "serviceAccount:${var.sa_dlp_email}"
}

# Cloud Function remote_get_table_policy_tags needs to read tables policy tags (metadata)
resource "google_project_iam_member" "data_project_iam_remote_func_bq_metadata_viewer" {
  project = var.target_project
  role = "roles/bigquery.metadataViewer"
  member = "serviceAccount:${var.sa_bq_remote_func_get_policy_tags_email}"
}

resource "google_project_iam_member" "data_project_iam_remote_func_datacatalog_viewer" {
  project = var.target_project
  role = "roles/roles/datacatalog.viewer"
  member = "serviceAccount:${var.sa_bq_remote_func_get_policy_tags_email}"
}

