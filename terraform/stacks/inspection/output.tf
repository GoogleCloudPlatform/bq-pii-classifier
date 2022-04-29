output "sa_inspection_dispatcher_email" {
  value = google_service_account.sa_inspection_dispatcher.email
}

output "sa_inspector_email" {
  value = google_service_account.sa_inspector.email
}