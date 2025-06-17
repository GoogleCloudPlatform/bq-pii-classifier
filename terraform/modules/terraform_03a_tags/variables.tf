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

variable "org_id" {
  type        = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
}

variable "dlp_tag_sensitivity_level_key_name" {
  type        = string
  description = "the key name for the DLP sensitivity levels tag"
  default     = "eip-cloud-dlp-sensitivity-level"
}

variable "ignore_dlp_sensitivity_key_name" {
  type        = string
  description = "the key name for the bypass DLP sensitivity levels tag used for raising objections by data owners"
  default     = "eip-bypass-cloud-dlp-sensitivity-level"
}

variable "dlp_tag_high_sensitivity_value_name" {
  type    = string
  default = "high"
}

variable "dlp_tag_moderate_sensitivity_value_name" {
  type    = string
  default = "moderate"
}

variable "dlp_tag_low_sensitivity_value_name" {
  type    = string
  default = "low"
}

variable "ignore_dlp_sensitivity_true_value_name" {
  type    = string
  default = "true"
}