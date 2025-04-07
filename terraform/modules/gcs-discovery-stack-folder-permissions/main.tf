############################### FOLDER LEVEL SETUP #################################################
####################### repeat on each data folder in scope or promote to org level ################

#### DLP Permissions #####

// DLP service account must be able to read GCS data to scan it
resource "google_folder_iam_member" "iam_member_dlp_sa_gcs_viewer" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.dlp_service_sa_email}"
}

// to add and remove tags to resources
resource "google_folder_iam_member" "iam_member_dlp_sa_tag_user" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = "roles/resourcemanager.tagUser"
  member = "serviceAccount:${var.dlp_service_sa_email}"
}

### Tagger Permissions

# The Tagger service must be able to get and set buckets metadata (i.e. to add labels) on the folder containing data buckets
resource "google_folder_iam_member" "iam_member_tagger_sa_gcs_custom_tagger_role" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = var.tagger_custom_role_id
  member = "serviceAccount:${var.tagger_sa_email}"
}

### Helper function permissions

# The Tagger service must be able to get and set buckets metadata (i.e. to add labels) on the folder containing data buckets
resource "google_folder_iam_member" "iam_member_func_get_buckets_metadata_sa_custom_role" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = var.get_buckets_metadata_func_custom_role_id
  member = "serviceAccount:${var.func_get_buckets_metadata_sa_email}"
}