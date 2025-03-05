
############################### ORG LEVEL SETUP ####################
#######################      deploy once per org      ################

resource "google_organization_iam_custom_role" "custom_role_tagger" {
  org_id      = var.dlp_config_org_id
  role_id     = "BqPiiClassifierBqTaggerServiceRole"
  title       = "Granular role for the Tagger service of the BQ PII Classifier solution to annotate BigQuery tables"
  description = "Allows viewing and updating storage buckets metadata."

  permissions = [
    "bigquery.tables.get", # get table metadata (e.g. labels, schema and policy tags) (not table data)
    "bigquery.tables.update", #  update table metadata (e.g. labels, schema and policy tags) (not table data)
    "bigquery.tables.setCategory", # to apply policy tags to columns
    "datacatalog.taxonomies.get", # to get existing policy tag names and report them
    "bigquery.datasets.get", # get dataset location (to determine regional policy tags)
  ]
  // replace this custom role with "roles/bigquery.dataOwner" and "" in case it can't be created

  stage = "GA"
}

// Tagger needs to read column profiles saved by the org-level dlp discovery configuration
resource "google_organization_iam_member" "iam_member_tagger_sa_column_profiles_reader" {
  org_id = var.dlp_config_org_id
  role   = "roles/dlp.columnDataProfilesReader"
  member = "serviceAccount:${var.sa_tagger_email}"
}


############################### FOLDER LEVEL SETUP #################################################
####################### repeat on each data folder in scope or promote to org level ################

// attach the granular custom role to Tagger on folder level
resource "google_folder_iam_member" "iam_member_tagger_sa_custom_role" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = google_organization_iam_custom_role.custom_role_tagger.id
  member = "serviceAccount:${var.sa_tagger_email}"
}

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

