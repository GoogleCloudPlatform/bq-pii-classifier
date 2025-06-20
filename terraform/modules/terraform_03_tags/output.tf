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

output "dlp_tag_high_sensitivity_namespaced_name" {
  value = google_tags_tag_value.dlp_high_sensitivity_value.namespaced_name
}

output "dlp_tag_moderate_sensitivity_namespaced_name" {
  value = google_tags_tag_value.dlp_moderate_sensitivity_value.namespaced_name
}

output "dlp_tag_low_sensitivity_namespaced_name" {
  value = google_tags_tag_value.dlp_low_sensitivity_value.namespaced_name
}

output "dlp_sensitivity_level_key_id" {
  value = google_tags_tag_key.dlp_sensitivity_level_key.id
}

output "ignore_dlp_key_id" {
  value = google_tags_tag_key.ignore_dlp_key.id
}

