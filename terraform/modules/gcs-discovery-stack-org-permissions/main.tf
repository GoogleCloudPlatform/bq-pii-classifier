
############################### ORG LEVEL SETUP ####################
#######################      deploy once per org      ################

####  CUSTOM ROLES #####

// Tagger service needs to read and update buckets metadata (e.g. adding labels). Instead of granting Storage Admin we create a granular custom role
resource "google_organization_iam_custom_role" "custom_role_tagger" {
  org_id      = var.org_id
  role_id     = "AnnotationsSolutionGcsTaggerServiceRole"
  title       = "CR for the GCP Annotations solution to annotate GCS bucktes"
  description = "Allows viewing and updating storage buckets metadata."

  permissions = [
    "storage.buckets.get", # to get the metadata of buckets
    "storage.buckets.update" # to attach labels to buckets
  ]

  stage = "GA"
}

// Granular permissions needed by the get-buckets-metadata helper function (used for dlp cost estimation and reviewing labels)
resource "google_organization_iam_custom_role" "custom_role_get_buckets_metadata_func" {
  org_id      = var.org_id
  role_id     = "AnnotationsSolutionGetBucketsMetadataFunc"
  title       = "CR for the GCP Annotations solution to get buckets metadata via a BQ remote function"
  description = "Allows viewing of storage objects in specific buckets."

  permissions = [
    "storage.buckets.list", # to list buckets under a project
    "storage.buckets.get", # to get buckets metadata
    "monitoring.timeSeries.list", #  to get total bucket size from monitoring api (instead of listing down objects to get their size
    "resourcemanager.projects.list" # to list projects under folder
  ]

  stage = "GA"
}

// The Tagger service must be able to read the DLP findings for GCS (i.e. FileStoreProfiles) to be able to "tag" the buckets accordingly
// Since the dlp scan config is stored on the org level, the role must be assigned on org level too
resource "google_organization_iam_member" "iam_member_tagger_sa_filestore_profiles_reader" {
  org_id = var.org_id
  role   = "roles/dlp.fileStoreProfilesReader"
  member = "serviceAccount:${var.tagger_sa_email}"
}
