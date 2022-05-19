output "config_view_infotype_policytag_map" {
  value = google_bigquery_table.config_view_infotypes_policytags_map.table_id
}

output "results_dataset" {
  value = google_bigquery_dataset.results_dataset.dataset_id
}

output "results_table_standard_dlp" {
  value = google_bigquery_table.standard_dlp_results_table.table_id
}

output "config_view_dataset_domain_map" {
  value = google_bigquery_table.config_view_dataset_domain_map.table_id
}

output "config_view_project_domain_map" {
  value = google_bigquery_table.config_view_project_domain_map.table_id
}

output "logging_table" {
  value = google_bigquery_table.logging_table.table_id
}