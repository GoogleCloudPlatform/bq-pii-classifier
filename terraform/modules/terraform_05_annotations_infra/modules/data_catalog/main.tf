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

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/data_catalog_policy_tag


### Create One  taxonomy and it's hierarchy

resource "google_data_catalog_taxonomy" "domain_taxonomy" {
  provider               = google
  project                = var.project
  region                 = var.region
  display_name           = title("${var.domain} Taxonomy ${var.taxonomy_number}${var.taxonomy_name_suffix}")
  description            = "Policy tags assigned by BQ PII Classifier for domain '${var.domain}' - ${var.taxonomy_number} in region '${var.region}'"
  activated_policy_types = var.data_catalog_taxonomy_activated_policy_types
}

locals {
  // get distinct list of parents
  // sort to create and index them in order
  parent_nodes = sort(distinct([
    for entry in var.classification_taxonomy : entry["classification"]
  ]))
}

resource "google_data_catalog_policy_tag" "parent_tags" {
  count        = length(local.parent_nodes)
  provider     = google
  taxonomy     = google_data_catalog_taxonomy.domain_taxonomy.id
  display_name = local.parent_nodes[count.index]
  # FIXME: this is a hack to propagate the domain the output variable "created_parent_tags". Find an alternative
  description = "${var.domain} | ${local.parent_nodes[count.index]}"
}

resource "google_data_catalog_policy_tag" "children_tags" {
  count    = length(var.classification_taxonomy)
  provider = google
  taxonomy = google_data_catalog_taxonomy.domain_taxonomy.id

  # How to decide the parent policy tag resource:
  #  get the list element from var.nodes based on the loop index
  #  get the "classification" field from the element
  #  get the index of the "parent" value from locals.parent_nodes
  parent_policy_tag = google_data_catalog_policy_tag.parent_tags[index
  (local.parent_nodes, lookup(var.classification_taxonomy[count.index], "classification", "NA"))].id

  display_name = var.classification_taxonomy[count.index]["policy_tag"]

  # FIXME: this is a hack to propagate the domain, info type and classification to the output variable "created_children_tags". Find an alternative
  description = "${var.domain} | ${lookup(var.classification_taxonomy[count.index], "classification", "NA")} | ${lookup(var.classification_taxonomy[count.index], "info_type", "NA")}"
}



