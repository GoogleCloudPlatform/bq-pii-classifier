output "sa_application_email" {
  value = google_service_account.sa_application.email
}

output "sa_tagger_gcs_email" {
  value = google_service_account.sa_tagger_gcs.email
}

output "sa_tagger_bq_email" {
  value = google_service_account.sa_tagger_bq.email
}