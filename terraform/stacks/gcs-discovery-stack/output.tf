output "bq_get_buckets_metadata_remote_function_deployment_status" {
  value = module.bq-remote-func-get-buckets-metadata.deploy_job_status
}

output "dispatcher_sa_email" {
  value = google_service_account.sa_tagging_dispatcher_gcs.email
}

output "tagger_sa_email" {
  value = google_service_account.sa_tagger_gcs.email
}

output "func_get_buckets_metadata_sa_email" {
  value = module.bq-remote-func-get-buckets-metadata.cloud_function_sa_email
}