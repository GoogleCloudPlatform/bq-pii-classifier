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

locals {
  apis_list = [
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "workflows.googleapis.com",
    "datacatalog.googleapis.com",
    "dlp.googleapis.com",
    "pubsub.googleapis.com",
    "batch.googleapis.com"
  ]

  apis_list_publishing_project = [
    "bigquery.googleapis.com",
  ]
}

resource "google_project_service" "enable_apis" {
  count   = length(local.apis_list)
  project = var.application_project
  service = local.apis_list[count.index]

  disable_on_destroy         = false
  disable_dependent_services = true
}

resource "google_project_service" "enable_apis_on_publishing_project" {
  count   = length(local.apis_list_publishing_project)
  project = var.publishing_project
  service = local.apis_list_publishing_project[count.index]

  disable_on_destroy         = false
  disable_dependent_services = true
}






