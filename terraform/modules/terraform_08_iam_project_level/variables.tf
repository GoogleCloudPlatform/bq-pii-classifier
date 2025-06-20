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

################################################################################
#                       COMMON VARIABLES
################################################################################

variable "application_project" {
  type        = string
  description = "GCP project name to deploy application components to"
}

variable "dlp_project" {
  type        = string
  description = "GCP project id that hosts DLP"
}

################################################################################
#                       BQ DISCOVERY STACK-SPECIFIC VARIABLES
################################################################################

variable "tagger_bq_service_account_name" {
  type    = string
  default = "annotations-bq"
}

################################################################################
#                       GCS DISCOVERY STACK-SPECIFIC VARIABLES
################################################################################

variable "tagger_gcs_service_account_name" {
  type    = string
  default = "annotations-gcs"
}
