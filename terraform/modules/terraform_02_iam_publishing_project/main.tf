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

data google_project "gcp_host_project" {
  project_id = var.application_project
}

locals {
  cloud_logging_service_account_email = "service-${data.google_project.gcp_host_project.number}@gcp-sa-logging.iam.gserviceaccount.com"

  application_service_account_email = "${var.application_service_account_name}@${var.application_project}.iam.gserviceaccount.com"

  sa_cloud_logging_roles_on_publishing_project = [
    "roles/bigquery.dataEditor", # for log sink to route logs to bigquery
  ]

  sa_application_roles_on_publsihing_project = [
    "roles/bigquery.dataEditor", # for dispatcher to write to dispatcher_runs tables
  ]
}


########################################################################################################################
#                                            IAM Bindings
########################################################################################################################

######### Application SA

resource "google_project_iam_member" "sa_application_roles_binding_on_publishing_project" {
  count   = length(local.sa_application_roles_on_publsihing_project)
  project = var.publishing_project
  role    = local.sa_application_roles_on_publsihing_project[count.index]
  member  = "serviceAccount:${local.application_service_account_email}"
}


######### DLP SA

resource "google_project_iam_member" "sa_dlp_roles_binding_on_publishing_project" {
  count   = length(var.dlp_service_agents_emails)
  project = var.publishing_project
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${var.dlp_service_agents_emails[count.index]}"
}

######### Cloud Logging SA
resource "google_project_iam_member" "sa_cloud_logging_roles_binding_on_publishing_project" {
  count   = length(local.sa_cloud_logging_roles_on_publishing_project)
  project = var.publishing_project
  role    = local.sa_cloud_logging_roles_on_publishing_project[count.index]
  member  = "serviceAccount:${local.cloud_logging_service_account_email}"
}



