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
#                                           Locals
########################################################################################################################

locals {
  sa_tagger_gcs_roles = [
    "roles/artifactregistry.reader", # to read container image for the service
    "roles/storage.objectAdmin",     # to read and write data to resources buckets (flags, resources, etc)
  ]
}

########################################################################################################################
#                                            Service Accounts
########################################################################################################################

resource "google_service_account" "sa_tagger_gcs" {
  project      = var.application_project
  account_id   = var.tagger_gcs_service_account_name
  display_name = "Data annotations service for GCS"
}

########################################################################################################################
#                                            IAM bindings
########################################################################################################################

resource "google_project_iam_member" "sa_tagger_gcs_roles_binding" {
  count   = length(local.sa_tagger_gcs_roles)
  project = var.application_project
  role    = local.sa_tagger_gcs_roles[count.index]
  member  = "serviceAccount:${google_service_account.sa_tagger_gcs.email}"
}


// push subscription SA needs to push to tagger SA
resource "google_service_account_iam_member" "sa_tagger_gcs_account_user_sa_tagger_gcs_tasks" {
  service_account_id = google_service_account.sa_tagger_gcs.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.sa_application.email}"
}
