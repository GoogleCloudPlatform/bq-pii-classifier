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
#                                          CUSTOM ROLES
########################################################################################################################

resource "google_organization_iam_custom_role" "custom_role_tagger_bq" {
  org_id      = var.org_id
  role_id     = var.tagger_bq_custom_role_id
  title       = "CR for the GCP Annotations solution to annotate BQ tables"
  description = "Allows viewing and updating storage buckets metadata."

  permissions = [
    "bigquery.tables.get",         # get table metadata (e.g. labels, schema and policy tags) (not table data)
    "bigquery.tables.update",      #  update table metadata (e.g. labels, schema and policy tags) (not table data)
    "bigquery.tables.setCategory", # to apply policy tags to columns
    "datacatalog.taxonomies.get",  # to get existing policy tag names and report them
    "bigquery.datasets.get",       # get dataset location (to determine regional policy tags)
  ]
  // replace this custom role with "roles/bigquery.dataOwner" and "" in case it can't be created

  stage = "GA"
}

########################################################################################################################
#                                          IAM BINDINGS
########################################################################################################################

// Tagger needs to read column profiles saved by the org-level dlp discovery configuration
resource "google_organization_iam_member" "iam_member_tagger_bq_sa_column_profiles_reader" {
  org_id = var.org_id
  role   = "roles/dlp.columnDataProfilesReader"
  member = "serviceAccount:${local.tagger_bq_service_account_email}"
}
########################################################################################################################
#                                            OUTPUT
########################################################################################################################

output "tagger_bq_custom_role_id" {
  value = google_organization_iam_custom_role.custom_role_tagger_bq.role_id
}