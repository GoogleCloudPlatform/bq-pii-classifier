output "sa_application_email" {
  value = google_service_account.sa_application.email
}

output "sa_tagger_gcs_email" {
  value = google_service_account.sa_tagger_gcs.email
}

output "sa_tagger_bq_email" {
  value = google_service_account.sa_tagger_bq.email
}

output "sa_application_name" {
  value = google_service_account.sa_application.account_id
}

output "sa_tagger_gcs_name" {
  value = google_service_account.sa_tagger_gcs.account_id
}

output "sa_tagger_bq_name" {
  value = google_service_account.sa_tagger_bq.account_id
}