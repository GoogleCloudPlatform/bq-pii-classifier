
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

// DLP service account must be able to profile tables and apply tags
// permissions: https://cloud.google.com/sensitive-data-protection/docs/iam-roles#dlp.orgdriver
resource "google_folder_iam_member" "iam_member_dlp_sa_gcs_viewer" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = "roles/dlp.orgdriver"
  member = "serviceAccount:${var.dlp_service_sa_email}"
}



