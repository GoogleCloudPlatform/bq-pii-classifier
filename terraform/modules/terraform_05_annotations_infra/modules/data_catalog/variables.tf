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

variable "project" {
  type = string
}
variable "region" {
  type = string
}

variable "domain" {
  type        = string
  description = "the domain name for the taxonomy"
}

variable "classification_taxonomy" {
  type = list(object({
    info_type          = string
    info_type_category = string
    # (standard | custom)
    policy_tag                 = string
    classification             = string
    inspection_template_number = number
    taxonomy_number            = number
  }))
  description = "A lis of Maps defining children nodes"
}

// Use ["FINE_GRAINED_ACCESS_CONTROL"] to restrict IAM access on tagged columns.
// Use [] NOT to restrict IAM access.
variable "data_catalog_taxonomy_activated_policy_types" {
  type        = list(string)
  description = "A lis of policy types for the created taxonomy(s)"
}

variable "taxonomy_number" { type = number }

variable "taxonomy_name_suffix" {
  type        = string
  default     = ""
  description = "Suffix added to taxonomy display name to make it unique within an org"
}
