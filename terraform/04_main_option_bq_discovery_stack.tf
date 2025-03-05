
module "bq-discovery-stack" {

  // deploy it only if the BIGQUERY_DISCOVERY is selected
  count = contains(var.supported_stacks, "BIGQUERY_DISCOVERY")? 1 : 0

  source = "./stacks/bq-discovery-stack"

  auto_dlp_results_table_name = var.auto_dlp_results_table_name
  bq_existing_labels_regex = var.bq_existing_labels_regex
  bq_remote_func_get_policy_tags_name = var.bq_remote_func_get_policy_tags_name
  bq_view_run_summary = google_bigquery_table.view_run_summary.table_id
  classification_taxonomy = var.classification_taxonomy
  compute_region = var.compute_region
  data_catalog_taxonomy_activated_policy_types = var.data_catalog_taxonomy_activated_policy_types
  data_region = var.data_region
  datastore_database_name = var.datastore_database_name
  default_domain_name = var.default_domain_name
  deploy_dlp_inspection_template_to_global_region = var.deploy_dlp_inspection_template_to_global_region
  dispatcher_service_max_cpu = var.dispatcher_service_max_cpu
  dispatcher_service_max_memory = var.dispatcher_service_max_memory
  dispatcher_service_timeout_seconds = var.dispatcher_service_timeout_seconds
  dispatcher_subscription_ack_deadline_seconds = var.dispatcher_subscription_ack_deadline_seconds
  dispatcher_subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
  dlp_bq_create_configuration_in_paused_state = var.dlp_bq_create_configuration_in_paused_state
  dlp_bq_dataset_regex = var.dlp_bq_dataset_regex
  dlp_bq_project_id_regex = var.dlp_bq_project_id_regex
  dlp_bq_reprofile_on_inspection_template_update_frequency = var.dlp_bq_reprofile_on_inspection_template_update_frequency
  dlp_bq_reprofile_on_schema_update_types = var.dlp_bq_reprofile_on_schema_update_types
  dlp_bq_reprofile_on_table_data_update_frequency = var.dlp_bq_reprofile_on_table_data_update_frequency
  dlp_bq_reprofile_on_table_data_update_types = var.dlp_bq_reprofile_on_table_data_update_types
  dlp_bq_reprofile_on_table_schema_update_frequency = var.dlp_bq_reprofile_on_table_schema_update_frequency
  dlp_bq_scan_folder_id = var.dlp_bq_scan_folder_id
  dlp_bq_scan_org_id = var.dlp_bq_scan_org_id
  dlp_bq_table_regex = var.dlp_bq_table_regex
  dlp_bq_table_types = var.dlp_bq_table_types
  dlp_inspection_templates_ids_list = local.dlp_inspection_templates_ids_list
  domain_mapping = var.domain_mapping
  gar_docker_repo_name = var.gar_docker_repo_name
  gcs_flags_bucket_name = google_storage_bucket.gcs_flags_bucket.id
  iam_mapping = var.iam_mapping
  info_types_map = local.info_types_map
  is_dry_run_labels = var.is_dry_run_labels
  is_dry_run_tags = var.is_dry_run_tags
  logging_table_name = google_bigquery_table.logging_table.table_id
  project = var.project
  promote_dlp_other_matches = var.promote_dlp_other_matches
  retain_dlp_tagger_pubsub_messages = var.retain_dlp_tagger_pubsub_messages
  sa_bq_remote_func_get_policy_tags = var.sa_bq_remote_func_get_policy_tags
  sa_tagger = var.sa_tagger
  sa_tagger_tasks = var.sa_tagger_tasks
  sa_tagging_dispatcher = var.sa_tagging_dispatcher
  sa_tagging_dispatcher_tasks = var.sa_tagging_dispatcher_tasks
  sa_workflows_bq = var.sa_workflows_bq
  source_data_regions = var.source_data_regions
  tagger_pubsub_sub = var.tagger_pubsub_sub
  tagger_pubsub_topic = var.tagger_pubsub_topic
  tagger_service_image = var.tagger_service_image
  tagger_service_name = var.tagger_service_name
  tagger_service_timeout_seconds = var.tagger_service_timeout_seconds
  tagger_subscription_ack_deadline_seconds = var.tagger_subscription_ack_deadline_seconds
  tagger_subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
  tagging_dispatcher_pubsub_sub = var.tagging_dispatcher_pubsub_sub
  tagging_dispatcher_pubsub_topic = var.tagging_dispatcher_pubsub_topic
  tagging_dispatcher_service_image = var.tagging_dispatcher_service_image
  tagging_dispatcher_service_name = var.tagging_dispatcher_service_name
  taxonomy_name_suffix = var.taxonomy_name_suffix
  terraform_data_deletion_protection = var.terraform_data_deletion_protection
  workflows_bq_description = var.workflows_bq_description
  workflows_bq_name = var.workflows_bq_name
}

// This module assigns roles and permissions to service accounts used in this solution on FOLDER and ORG level (and not the host project)
// The Terraform service account needs certain folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles folder level
module "data-folder-permissions-for-bq-discovery-stack" {

  source = "./modules/org-and-folder-permissions-for-bq-discovery-stack"

  // deploy it only if the BIGQUERY_DISCOVERY is selected
  count = contains(var.supported_stacks, "BIGQUERY_DISCOVERY")? 1 : 0

  dlp_config_folder_id                    = var.dlp_bq_scan_folder_id

  # default: tagger@<host project id>.iam.gserviceaccount.com
  sa_tagger_email                         = module.bq-discovery-stack[0].sa_tagger_email
  # default: tag-dispatcher@<host project id>.iam.gserviceaccount.com
  sa_tagging_dispatcher_email             = module.bq-discovery-stack[0].sa_tagging_dispatcher_email
  # "service-${dlp scan config host project number}@dlp-api.iam.gserviceaccount.com"
  dlp_service_sa_email                    = local.dlp_service_account_email
  # default: sa-func-get-policy-tags@<host project id>.iam.gserviceaccount.com
  sa_bq_remote_func_get_policy_tags_email = module.bq-discovery-stack[0].sa_bq_remote_func_get_policy_tags_email

  dlp_config_org_id = var.dlp_bq_scan_org_id
}