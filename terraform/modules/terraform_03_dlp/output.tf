output "dlp_inspection_templates" {
  value = local.created_dlp_inspection_templates
}

output "dlp_gcs_notifications_topic" {
  value = google_pubsub_topic.dlp_gcs_topic.name
}

output "dlp_bq_notifications_topic" {
  value = google_pubsub_topic.dlp_bq_topic.name
}

output "dlp_results_dataset" {
  value = google_bigquery_dataset.results_dataset.id
}