
############################### FOLDER LEVEL SETUP #################################################
####################### repeat on each data folder in scope or promote to org level ################

###### TAGGER #####

// attach the granular custom role to Tagger on folder level
resource "google_folder_iam_member" "iam_member_tagger_sa_custom_role" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = var.tagger_custom_role_id
  member = "serviceAccount:${var.sa_tagger_email}"
}

####### DLP SA ########

# dlp service account needs to read and inspect tables
resource "google_folder_iam_member" "data_folder_iam_dlp_sa_bq_data_viewer" {
  folder = "folders/${var.dlp_config_folder_id}"
  role = "roles/bigquery.dataViewer"
  member = "serviceAccount:${var.dlp_service_sa_email}"
}

# dlp sa needs to read columns that are tagged with policy tags created
resource "google_folder_iam_member" "data_folder_iam_dlp_sa_category_fine_reader" {
  folder = "folders/${var.dlp_config_folder_id}"
  role = "roles/datacatalog.categoryFineGrainedReader"
  member = "serviceAccount:${var.dlp_service_sa_email}"
}

// to add and remove tags to resources
resource "google_folder_iam_member" "iam_member_dlp_sa_tag_user" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = "roles/resourcemanager.tagUser"
  member = "serviceAccount:${var.dlp_service_sa_email}"
}

##### Helper functions SA ######

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

