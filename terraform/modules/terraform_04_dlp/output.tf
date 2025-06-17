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

output "dlp_inspection_templates" {
  value = local.created_dlp_inspection_templates
}

output "dlp_gcs_notifications_topic" {
  value = google_pubsub_topic.dlp_gcs_topic.name
}

output "dlp_bq_notifications_topic" {
  value = google_pubsub_topic.dlp_bq_topic.name
}

output "dlp_results_dataset" {
  value = google_bigquery_dataset.results_dataset.dataset_id
}

output "dlp_gcs_folders" {
  value = [for x in var.dlp_gcs_discovery_configurations : x.folder_id]
}

output "dlp_bq_folders" {
  value = [for x in var.dlp_bq_discovery_configurations : x.folder_id]
}

output "dlp_service_account_email" {
  value = "service-${data.google_project.gcp_host_project.number}@dlp-api.iam.gserviceaccount.com"
}