output "tagger_custom_role_id" {
  value = google_organization_iam_custom_role.custom_role_tagger.id
}

output "get_buckets_metadata_func_custom_role_id" {
  value = google_organization_iam_custom_role.custom_role_get_buckets_metadata_func.id
}