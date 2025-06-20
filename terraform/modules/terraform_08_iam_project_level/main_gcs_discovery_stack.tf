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
#                                          IAM BINDINGS
########################################################################################################################

locals {

  # These are the required permissions for the GCS tagger service on the data/dlp project (in a project-level dlp deployment)
  # for simplifications, we don't create custom roles on org level and use built-in roles instead.
  # permissions = [
  # "storage.buckets.get",   # to get the metadata of buckets
  # "storage.buckets.update" # to attach labels to buckets
  # ]
  tagger_gcs_sa_roles_on_dlp_project = [
    "roles/dlp.fileStoreProfilesReader", # to fetch dlp results
    "roles/storage.admin" # to annotate the buckets
  ]
}

// Tagger needs to read column profiles saved by the org-level dlp discovery configuration
resource "google_project_iam_member" "iam_member_tagger_gcs_sa_bindings" {
  count = length(local.tagger_gcs_sa_roles_on_dlp_project)
  project = var.dlp_project
  role   = local.tagger_gcs_sa_roles_on_dlp_project[count.index]
  member = "serviceAccount:${local.tagger_gcs_service_account_email}"
}



