# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/data_catalog_policy_tag


### Create One  taxonomy and it's hierarchy

resource "google_data_catalog_taxonomy" "domain_taxonomy" {
  provider = google-beta
  project = var.project
  region = var.region
  display_name = var.domain
  description = "A collection of policy tags assigned by BQ security classifier for domain '${var.domain}'"
  activated_policy_types = [
    "FINE_GRAINED_ACCESS_CONTROL"]
}

locals {
  // get distinct list of parents
  // sort to create and index them in order
  parent_nodes = sort(distinct([
    for entry in var.nodes : lookup(entry, "classification")
    ]))
}

resource "google_data_catalog_policy_tag" "parent_tags" {
  count = length(local.parent_nodes)
  provider = google-beta
  taxonomy = google_data_catalog_taxonomy.domain_taxonomy.id
  display_name = local.parent_nodes[count.index]
  # FIXME: this is a hack to propagate the domain the output variable "created_parent_tags". Find an alternative
  description = "${var.domain} | ${local.parent_nodes[count.index]}"
}

resource "google_data_catalog_policy_tag" "children_tags" {
  count = length(var.nodes)
  provider = google-beta
  taxonomy = google_data_catalog_taxonomy.domain_taxonomy.id

  # How to decide the parent policy tag resource:
  #  get the list element from var.nodes based on the loop index
  #  get the "classification" field from the element
  #  get the index of the "parent" value from locals.parent_nodes
  parent_policy_tag = google_data_catalog_policy_tag.parent_tags[index
  (local.parent_nodes, lookup(var.nodes[count.index], "classification", "NA"))].id

  display_name = lookup(var.nodes[count.index],"policy_tag")

  # FIXME: this is a hack to propagate the domain and infotype to the output variable "created_children_tags". Find an alternative
  description = "${var.domain} | ${lookup(var.nodes[count.index],"info_type", "NA")}"
}



