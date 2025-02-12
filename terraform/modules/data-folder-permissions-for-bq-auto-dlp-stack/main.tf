
# dlp service account needs to read and inspect tables
resource "google_folder_iam_member" "data_folder_iam_dlp_sa_bq_data_viewer" {
  folder = "folders/${var.dlp_config_folder_id}"
  role = "roles/bigquery.dataViewer"
  member = "serviceAccount:${var.dlp_service_sa_email}"
}

# Tagging Dispatcher needs to know the location of datasets
resource "google_folder_iam_member" "data_folder_iam_tagging_dispatcher_bq_metadata_viewer" {
  folder = "folders/${var.dlp_config_folder_id}"
  role = "roles/bigquery.metadataViewer"
  member = "serviceAccount:${var.sa_tagging_dispatcher_email}"
}

# Tagger needs to read table schema and update tables policy tags
resource "google_folder_iam_member" "data_folder_tagger_bq_data_owner" {
  folder = "folders/${var.dlp_config_folder_id}"
  role = "roles/bigquery.dataOwner"
  member = "serviceAccount:${var.sa_tagger_email}"
}

# Cloud Function remote_get_table_policy_tags needs to read tables policy tags (metadata)
resource "google_folder_iam_member" "data_folder_iam_remote_func_bq_metadata_viewer" {
  folder = "folders/${var.dlp_config_folder_id}"
  role = "roles/bigquery.metadataViewer"
  member = "serviceAccount:${var.sa_bq_remote_func_get_policy_tags_email}"
}

resource "google_folder_iam_member" "data_folder_iam_remote_func_datacatalog_viewer" {
  folder = "folders/${var.dlp_config_folder_id}"
  role = "roles/datacatalog.viewer"
  member = "serviceAccount:${var.sa_bq_remote_func_get_policy_tags_email}"
}

