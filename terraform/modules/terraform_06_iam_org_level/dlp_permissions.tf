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
#                                          IAM BINDINGS
########################################################################################################################

locals {
  dlp_service_account_roles = [
    "roles/dlp.admin",
    "roles/cloudasset.viewer"
  ]
}

// Tagger needs to read column profiles saved by the org-level dlp discovery configuration
resource "google_organization_iam_member" "dlp_service_account_iam_bindings" {
  count  = length(local.dlp_service_account_roles)
  org_id = var.org_id
  role   = local.dlp_service_account_roles[count.index]
  member = "serviceAccount:${var.dlp_service_account_email}"
}