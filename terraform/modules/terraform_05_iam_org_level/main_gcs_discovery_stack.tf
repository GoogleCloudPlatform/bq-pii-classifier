########################################################################################################################
#                                          STACK-SPECIFIC VARIABLES
########################################################################################################################

variable "tagger_gcs_service_account_name" {
  type = string
  default = "annotations-gcs"
}

variable "tagger_gcs_custom_role_id" {
  type        = string
  description = "The custom role ID to be created at the organization level for the GCS Tagger service."
  default     = "AnnotationsSolutionGcsTaggerServiceRole"
}
########################################################################################################################
#                                          DATA & LOCALS
########################################################################################################################

locals {
  tagger_gcs_service_account_email = "${var.tagger_gcs_service_account_name}@${var.application_project}.iam.gserviceaccount.com"
}

########################################################################################################################
#                                          CUSTOM ROLES
########################################################################################################################

// Tagger service needs to read and update buckets metadata (e.g. adding labels). Instead of granting Storage Admin we create a granular custom role
resource "google_organization_iam_custom_role" "custom_role_tagger_gcs" {
  org_id      = var.org_id
  role_id     = var.tagger_gcs_custom_role_id
  title       = "CR for the GCP Annotations solution to annotate GCS bucktes"
  description = "Allows viewing and updating storage buckets metadata."

  permissions = [
    "storage.buckets.get", # to get the metadata of buckets
    "storage.buckets.update" # to attach labels to buckets
  ]

  stage = "GA"
}

########################################################################################################################
#                                          IAM BINDINGS
########################################################################################################################

// The Tagger service must be able to read the DLP findings for GCS (i.e. FileStoreProfiles) to be able to "tag" the buckets accordingly
// Since the dlp scan config is stored on the org level, the role must be assigned on org level too
resource "google_organization_iam_member" "iam_member_tagger_gcs_sa_filestore_profiles_reader" {
  org_id = var.org_id
  role   = "roles/dlp.fileStoreProfilesReader"
  member = "serviceAccount:${local.tagger_gcs_service_account_email}"
}

########################################################################################################################
#                                            OUTPUT
########################################################################################################################


output "tagger_gcs_custom_role_id" {
  value = google_organization_iam_custom_role.custom_role_tagger_gcs.role_id
}

