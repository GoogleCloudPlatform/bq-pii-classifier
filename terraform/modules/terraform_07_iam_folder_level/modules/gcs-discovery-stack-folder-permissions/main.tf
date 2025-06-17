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

############################### FOLDER LEVEL SETUP #################################################
####################### repeat on each data folder in scope or promote to org level ################

#### DLP Permissions #####

// DLP service account must be able to profile buckets and apply tags
// permissions: https://cloud.google.com/sensitive-data-protection/docs/iam-roles#dlp.orgdriver
resource "google_folder_iam_member" "iam_member_dlp_sa_gcs_viewer" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = "roles/dlp.orgdriver"
  member = "serviceAccount:${var.dlp_service_sa_email}"
}

### Tagger Permissions

# The Tagger service must be able to get and set buckets metadata (i.e. to add labels) on the folder containing data buckets
resource "google_folder_iam_member" "iam_member_tagger_sa_gcs_custom_tagger_role" {
  folder = "folders/${var.dlp_config_folder_id}"
  role   = var.tagger_custom_role_id
  member = "serviceAccount:${var.tagger_sa_email}"
}

