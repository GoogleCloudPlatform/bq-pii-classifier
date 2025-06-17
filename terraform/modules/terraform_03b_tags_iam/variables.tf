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

variable "dlp_sensitivity_level_key_id" {
  type        = string
  description = "The ID of the 'DLP sensitivity' tag key"
}

variable "ignore_dlp_key_id" {
  type        = string
  description = "The ID of the 'Ignore/Bypass DLP Sensitivity' tag key"
}

variable "dlp_tag_sensitivity_level_key_iam_tag_user_principles" {
  type        = list(string)
  description = "List of principles to have roles/resourcemanager.tagUser on the 'DLP sensitivity' tags"
}

variable "ignore_dlp_sensitivity_key_iam_tag_user_principles" {
  type        = list(string)
  description = "List of principles to have roles/resourcemanager.tagUser on the 'Ignore DLP Sensitivity' tags"
}