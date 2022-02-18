

output "sa_tagging_dispatcher_email" {
  value = google_service_account.sa_tagging_dispatcher.email
}


output "sa_tagger_email" {
  value = google_service_account.sa_tagger.email
}

output "sa_tagging_dispatcher_tasks_email" {
  value = google_service_account.sa_tagging_dispatcher_tasks.email
}


output "sa_tagger_tasks_email" {
  value = google_service_account.sa_tagger_tasks.email
}

output "local_parent_tags_with_members_list" {
  value = local.parent_tags_with_members_list
}

output "local_iam_members_list" {
  value = local.iam_members_list
}

output "debug_policy_tag_readers" {
  value = google_data_catalog_policy_tag_iam_member.policy_tag_reader

}