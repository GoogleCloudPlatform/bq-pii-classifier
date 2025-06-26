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
  tagger_bq_service_account_email = "${var.tagger_bq_service_account_name}@${var.application_project}.iam.gserviceaccount.com"
}

########################################################################################################################
#                                          IAM BINDINGS
########################################################################################################################
locals {

  tagger_bq_sa_roles_on_dlp_project = [
    "roles/dlp.columnDataProfilesReader", # to fetch dlp results
    "roles/bigquery.dataOwner", # to get metadata and add labels and tags
    "roles/datacatalog.viewer", # to read policy tags if exist
    "roles/resourcemanager.tagUser" # to delete tags from resources (for the cleaner service)
  ]
}

// Tagger needs to read column profiles saved by the org-level dlp discovery configuration
resource "google_project_iam_member" "iam_member_tagger_bq_sa_bindings" {
  count = length(local.tagger_bq_sa_roles_on_dlp_project)
  project = var.dlp_project
  role   = local.tagger_bq_sa_roles_on_dlp_project[count.index]
  member = "serviceAccount:${local.tagger_bq_service_account_email}"
}
