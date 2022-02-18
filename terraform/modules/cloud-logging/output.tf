output "service_account" {
  value = google_logging_project_sink.bigquery-logging-sink.writer_identity
}