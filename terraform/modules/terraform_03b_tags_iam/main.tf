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
#                                    Tags IAM
##############################################################

# principles need to be tag users on the tag and the resource to create a binding

resource "google_tags_tag_key_iam_member" "dlp_sensitivity_level_key_iam_tag_user" {
  count   = length(var.dlp_tag_sensitivity_level_key_iam_tag_user_principles)
  member  = var.dlp_tag_sensitivity_level_key_iam_tag_user_principles[count.index]
  role    = "roles/resourcemanager.tagUser"
  tag_key = var.dlp_sensitivity_level_key_id
}

resource "google_tags_tag_key_iam_member" "ignore_dlp_key_iam_tag_user" {
  count   = length(var.ignore_dlp_sensitivity_key_iam_tag_user_principles)
  member  = var.ignore_dlp_sensitivity_key_iam_tag_user_principles[count.index]
  role    = "roles/resourcemanager.tagUser"
  tag_key = var.ignore_dlp_key_id
}