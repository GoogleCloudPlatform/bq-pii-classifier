#
#
#  Copyright 2025 Google LLC
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       https://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#  implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#

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
    "storage.buckets.get",   # to get the metadata of buckets
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

