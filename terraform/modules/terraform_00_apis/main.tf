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
    "batch.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]

  apis_list_publishing_project = [
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]

  apis_list_dlp_projects = [
    "dlp.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]

  dlp_project_api_pairs = {
    for pair in setproduct(var.dlp_projects, local.apis_list_dlp_projects) :
    "${pair[0]}-${pair[1]}" => {
      project_id = pair[0]
      api        = pair[1]
    }
  }
}

resource "google_project_service" "enable_apis" {
  count = length(local.apis_list)
  project = var.application_project
  service = local.apis_list[count.index]

  disable_on_destroy         = false
  disable_dependent_services = true
}

resource "google_project_service" "enable_apis_on_publishing_project" {
  count = length(local.apis_list_publishing_project)
  project = var.publishing_project
  service = local.apis_list_publishing_project[count.index]

  disable_on_destroy         = false
  disable_dependent_services = true
}

resource "google_project_service" "apis" {
  for_each                   = local.dlp_project_api_pairs

  project                    = each.value.project_id
  service                    = each.value.api
  disable_on_destroy         = false
  disable_dependent_services = true
}

// create the DLP service account in the application project without waiting for a trigger (e.g. job or config creation)
// this step is needed to resolve deployment deadlocks between creating DLP configs that are using tags and granting
// permissions on the DLP SA on these tags
// if you can't run this, then run it in a terminal using `gcloud beta services identity create --service=dlp.googleapis.com --project=APPLICATION_PROJECT_ID`
resource "google_project_service_identity" "application_project_dlp_service_identity" {
  provider = google-beta

  project = var.application_project
  service = "dlp.googleapis.com"
}

// force create the workflows service account
resource "google_project_service_identity" "workflows_service_identity" {
  provider = google-beta

  project = var.application_project
  service = "workflows.googleapis.com"
}

resource "google_project_service_identity" "dlp_projects_dlp_service_identity" {
  for_each = var.dlp_projects

  provider = google-beta

  project = each.value
  service = "dlp.googleapis.com"
}








