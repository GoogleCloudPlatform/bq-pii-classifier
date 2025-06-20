data "google_project" "dlp_agent_project" {
  project_id = var.dlp_agent_project_id
}

output "dlp_agent_service_account_email" {
  value = "service-${data.google_project.dlp_agent_project.number}@dlp-api.iam.gserviceaccount.com"
}