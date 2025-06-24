output "application_project_dlp_service_identity_email" {
  value = google_project_service_identity.application_project_dlp_service_identity.email
}

output "dlp_projects_service_identity_emails" {
  value = distinct(concat([
    for identity in google_project_service_identity.dlp_projects_dlp_service_identity :identity.email
  ],
    [google_project_service_identity.application_project_dlp_service_identity.email]
  ))
}

output "application_project_workflows_email" {
  value = google_project_service_identity.workflows_service_identity.email
}