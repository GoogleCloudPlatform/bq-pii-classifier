output "bq_get_policy_tags_remote_function_deployment_status" {
  value = module.bq-remote-func-get-table-policy-tags.deploy_job_status
}
output "org_id" {
  value = data.google_project.gcp_project.org_id
}