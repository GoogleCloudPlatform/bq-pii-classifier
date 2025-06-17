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

output "created_taxonomy" {
  value = google_data_catalog_taxonomy.domain_taxonomy
}

output "created_parent_tags" {
  value = [for entry in google_data_catalog_policy_tag.parent_tags : {
    id           = entry.id
    display_name = entry.display_name
    domain       = trim(element(split("|", entry.description), 0), " ")
  }]
}

output "created_children_tags" {
  value = [for entry in google_data_catalog_policy_tag.children_tags : {
    policy_tag_id  = entry.id
    domain         = trim(element(split("|", entry.description), 0), " ")
    classification = trim(element(split("|", entry.description), 1), " ")
    info_type      = trim(element(split("|", entry.description), 2), " ")
    region         = var.region
  }]
}

