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

#############################################################
#                                    DLP Sensitivity Tags
##############################################################

resource "google_tags_tag_key" "dlp_sensitivity_level_key" {
  parent      = "organizations/${var.org_id}"
  short_name  = var.dlp_tag_sensitivity_level_key_name
  description = "Cloud DLP data sensitivity level."
}

resource "google_tags_tag_value" "dlp_high_sensitivity_value" {
  parent      = google_tags_tag_key.dlp_sensitivity_level_key.id
  short_name  = var.dlp_tag_high_sensitivity_value_name
  description = "DLP detected potential high sensitivity pii (SPII)"
}

resource "google_tags_tag_value" "dlp_moderate_sensitivity_value" {
  parent      = google_tags_tag_key.dlp_sensitivity_level_key.id
  short_name  = var.dlp_tag_moderate_sensitivity_value_name
  description = "DLP detected potential sensitive information that is not classified as high"
}

resource "google_tags_tag_value" "dlp_low_sensitivity_value" {
  parent      = google_tags_tag_key.dlp_sensitivity_level_key.id
  short_name  = var.dlp_tag_low_sensitivity_value_name
  description = "DLP didn't detect sensitive information"
}

#############################################################
#                                    DLP Ignore Tags
##############################################################

resource "google_tags_tag_key" "ignore_dlp_key" {
  parent      = "organizations/${var.org_id}"
  short_name  = var.ignore_dlp_sensitivity_key_name
  description = "A signal to ignore Cloud DLP automated sensitivity tag."
}

resource "google_tags_tag_value" "ignore_dlp_true_value" {
  parent      = google_tags_tag_key.ignore_dlp_key.id
  short_name  = var.ignore_dlp_sensitivity_true_value_name
  description = "Ignore Cloud DLP automated sensitivity tag."
}