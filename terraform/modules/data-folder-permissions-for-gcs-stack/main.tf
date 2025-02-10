####  CUSTOM ROLES #####

// Tagger service needs to read and update buckets metadata (e.g. adding labels). Instead of granting Storage Admin we create a granular custom role
resource "google_organization_iam_custom_role" "custom_role_tagger" {
  org_id      = var.dlp_config_org_id
  role_id     = "BqPiiClassifierTaggerServiceRole"
  title       = "Granular role for the Tagger service of the BQ PII Classifier solution to get and update buckets"
  description = "Allows viewing and updating storage buckets metadata."

  permissions = [
    "storage.buckets.get", # to get the metadata of buckets
    "storage.buckets.update" # to attach labels to buckets
  ]

  stage = "GA"
}

// Granular permissions needed by the get-buckets-metadata helper function (used for dlp cost estimation and reviewing labels)
resource "google_organization_iam_custom_role" "custom_role_get_buckets_metadata_func" {
  org_id      = var.dlp_config_org_id
  role_id     = "BqPiiClassifierGetBucketsMetadataFunc"
  title       = "Granular role for the get-buckets-metadata helper function of the BQ PII Classifier solution"
  description = "Allows viewing of storage objects in specific buckets."

  permissions = [
    "storage.buckets.list", # to list buckets under a project
    "storage.buckets.get", # to get buckets metadata
    "monitoring.timeSeries.list", #  to get total bucket size from monitoring api (instead of listing down objects to get their size
    "resourcemanager.projects.list" # to list projects under folder
  ]

  stage = "GA"
}

#### IAM MEMBERS #####

// DLP service account must be able to read GCS data to scan it
resource "google_folder_iam_member" "iam_member_dlp_sa_gcs_viewer" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.dlp_service_sa_email}"
}

### Dispatcher Permissions

// The dispatcher service must be able to read the DLP findings for GCS (i.e. FileStoreProfiles) to be able to generate
// re-tagging requests per profile
resource "google_organization_iam_member" "iam_member_tagger_sa_dispatcher_filestore_profiles_reader" {
  org_id = var.dlp_config_org_id
  role   = "roles/dlp.fileStoreProfilesReader"
  member = "serviceAccount:${var.dispatcher_sa_email}"
}

### Tagger Permissions

// The Tagger service must be able to read the DLP findings for GCS (i.e. FileStoreProfiles) to be able to "tag" the buckets accordingly
// Since the dlp scan config is stored on the org level, the role must be assigned on org level too
resource "google_organization_iam_member" "iam_member_tagger_sa_filestore_profiles_reader" {
  org_id = var.dlp_config_org_id
  role   = "roles/dlp.fileStoreProfilesReader"
  member = "serviceAccount:${var.tagger_sa_email}"
}

# The Tagger service must be able to get and set buckets metadata (i.e. to add labels) on the folder containing data buckets
resource "google_folder_iam_member" "iam_member_tagger_sa_gcs_custom_tagger_role" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = google_organization_iam_custom_role.custom_role_tagger.id # "organizations/${google_organization_iam_custom_role.custom_role_tagger.name}"
  member = "serviceAccount:${var.tagger_sa_email}"
}

### Helper function permissions

# The Tagger service must be able to get and set buckets metadata (i.e. to add labels) on the folder containing data buckets
resource "google_folder_iam_member" "iam_member_func_get_buckets_metadata_sa_custom_role" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = google_organization_iam_custom_role.custom_role_get_buckets_metadata_func.id #"organizations/${var.dlp_config_org_id}/roles/${google_organization_iam_custom_role.custom_role_get_buckets_metadata_func.id}"
  member = "serviceAccount:${var.func_get_buckets_metadata_sa_email}"
}