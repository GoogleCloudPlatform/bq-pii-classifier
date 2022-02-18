output "bq_view_dlp_fields_findings" {
  value = module.bigquery.bq_view_dlp_fields_findings
}

output "dlp_inspection_template_id" {
  value = module.dlp.template_id
}

output "bq_results_dataset" {
  value = module.bigquery.results_dataset
}

output "tagger_topic_name" {
  value = module.pubsub-tagger.topic-name
}

