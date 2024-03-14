
output "dlp_inspection_template_id" {
  value = module.dlp.template_id
}

output "bq_results_dataset" {
  value = module.bigquery.results_dataset
}

output "tagger_topic_name" {
  value = module.pubsub-tagger.topic-name
}

output "tagger_topic_id" {
  value = module.pubsub-tagger.topic-id
}

output "sa_tagging_dispatcher_email" {
  value = module.iam.sa_tagging_dispatcher_email
}

output "sa_tagger_email" {
  value = module.iam.sa_tagger_email
}

output "info_type_map" {
  value = local.info_types_map
}

