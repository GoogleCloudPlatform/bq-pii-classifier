output "bq_get_policy_tags_remote_function_deployment_status" {
  value = module.bq-remote-func-get-table-policy-tags.deploy_job_status
}

output "bq_get_buckets_metadata_remote_function_deployment_status" {
  value = module.gcs-discovery-stack.bq_get_buckets_metadata_remote_function_deployment_status
}