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

variable "application_project" {
  type        = string
  description = "GCP project name to deploy application components to"
}

variable "application_service_account_name" {
  type        = string
  default     = "annotations-app"
  description = "Name of the service account to run the application components"
}

variable "tagger_gcs_service_account_name" {
  type        = string
  default     = "annotations-gcs"
  description = "Name of the service account to run the GCS annotations service"
}

variable "tagger_bq_service_account_name" {
  type        = string
  default     = "annotations-bq"
  description = "Name of the service account to run the BigQuery annotations service"
}