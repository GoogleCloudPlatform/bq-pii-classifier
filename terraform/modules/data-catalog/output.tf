output "created_taxonomy" {
  value = google_data_catalog_taxonomy.domain_taxonomy
}

output "created_parent_tags" {
  value = [for entry in google_data_catalog_policy_tag.parent_tags: {
    id = entry.id
    display_name = entry.display_name
    domain = trim(element(split("|", entry.description), 0), " ")
  }]
}

output "created_children_tags" {
  value = [for entry in google_data_catalog_policy_tag.children_tags: {
    policy_tag_id = entry.id
    domain = trim(element(split("|", entry.description), 0), " ")
    info_type = trim(element(split("|", entry.description), 1), " ")
  }]
}

