
output "sa_tagger_email" {
  value = google_service_account.sa_tagger.email
}

output "sa_tagging_dispatcher_email" {
  value = google_service_account.sa_tagging_dispatcher.email
}

output "sa_bq_remote_func_get_policy_tags_email" {
  value = module.bq-remote-func-get-table-policy-tags.cloud_function_sa_email
}