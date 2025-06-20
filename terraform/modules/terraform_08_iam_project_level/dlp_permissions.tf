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

data "google_project" "dlp_project" {
  project_id = var.dlp_project
}

// DLP service account must be able to profile buckets and apply tags
// permissions: https://cloud.google.com/sensitive-data-protection/docs/iam-roles#dlp.projectdriver
resource "google_project_iam_member" "iam_member_dlp_sa_project_driver" {
  project = var.dlp_project
  role   = "roles/dlp.projectdriver"
  member = "serviceAccount:service-${data.google_project.dlp_project.number}@dlp-api.iam.gserviceaccount.com"
}