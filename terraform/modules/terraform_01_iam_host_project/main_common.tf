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
  sa_application_roles_on_host_project = [
    "roles/bigquery.jobUser",        # for dispatcher to run the query that reads DLP findings
    "roles/batch.agentReporter",     # for dispatcher to run Cloud Batch jobs
    "roles/logging.logWriter",       # for dispatcher to run Cloud Batch jobs,
    "roles/artifactregistry.reader", # for dispatcher to read container image for the service
    "roles/batch.jobsEditor",        # for cloud workflows  to run batch jobs
    "roles/pubsub.publisher",        # for dispatcher to publish messages to PubSub
  ]
}

########################################################################################################################
#                                            Service Accounts
########################################################################################################################

resource "google_service_account" "sa_application" {
  project      = var.application_project
  account_id   = var.application_service_account_name
  display_name = "Service account to run the data annotations application components"
}


########################################################################################################################
#                                            IAM Bindings
########################################################################################################################

######### Application SA

resource "google_project_iam_member" "sa_application_roles_binding_on_host_project" {
  count   = length(local.sa_application_roles_on_host_project)
  project = var.application_project
  role    = local.sa_application_roles_on_host_project[count.index]
  member  = "serviceAccount:${google_service_account.sa_application.email}"
}

# sa_application must have roles/iam.serviceAccountUser on itself for services running it can invoke each other
resource "google_service_account_iam_member" "sa_application_service_account_user" {
  service_account_id = google_service_account.sa_application.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.sa_application.email}"
}

######### DLP SA

resource "google_project_iam_member" "sa_dlp_roles_binding_on_host_project" {
  count   = length(var.dlp_service_agents_emails)
  project = var.application_project
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.dlp_service_agents_emails[count.index]}"
}



