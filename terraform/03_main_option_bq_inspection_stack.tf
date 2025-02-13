
module "bq-inspection-stack" {
  source = "./stacks/bq-inspection-stack"
  // deploy the inspection stack only if we are not in bq auto_dlp_mode (i.e. bq inspection stack)
  count  = local.is_auto_dlp_mode ? 0 : 1

  bigquery_dataset_name           = google_bigquery_dataset.results_dataset.dataset_id
  cloud_scheduler_account         = local.cloud_scheduler_account_email
  cron_expression                 = var.inspection_cron_expression
  datasets_exclude_list           = var.datasets_exclude_list
  datasets_include_list           = var.datasets_include_list
  dispatcher_service_image        = local.inspection_dispatcher_service_image_uri
  dlp_inspection_templates_ids    = local.created_dlp_inspection_templates
  inspector_service_image         = local.inspector_service_image_uri
  project                         = var.project
  projects_include_list           = var.projects_include_list
  compute_region                  = var.compute_region
  data_region                     = var.data_region
  source_data_regions             = var.source_data_regions
  table_scan_limits_json_config   = jsonencode(var.table_scan_limits_json_config)
  tables_exclude_list             = var.tables_exclude_list
  tagger_topic_id                 = module.pubsub-tagger.topic-id
  dispatcher_pubsub_sub           = var.inspection_dispatcher_pubsub_sub
  dispatcher_pubsub_topic         = var.inspection_dispatcher_pubsub_topic
  dispatcher_service_name         = var.inspection_dispatcher_service_name
  inspector_pubsub_sub            = var.inspector_pubsub_sub
  inspector_pubsub_topic          = var.inspector_pubsub_topic
  inspector_service_name          = var.inspector_service_name
  sa_inspector                    = var.sa_inspector
  sa_inspector_tasks              = var.sa_inspector_tasks
  scheduler_name                  = var.inspection_scheduler_name
  standard_dlp_results_table_name = var.standard_dlp_results_table_name
  sa_inspection_dispatcher        = var.sa_inspection_dispatcher
  sa_inspection_dispatcher_tasks  = var.sa_inspection_dispatcher_tasks
  dlp_max_findings_per_item       = var.dlp_max_findings_per_item
  dlp_min_likelihood              = var.dlp_min_likelihood
  dlp_sampling_method             = var.dlp_sampling_method
  gcs_flags_bucket_name           = google_storage_bucket.gcs_flags_bucket.name

  dispatcher_service_timeout_seconds                 = var.dispatcher_service_timeout_seconds
  dispatcher_subscription_ack_deadline_seconds       = var.dispatcher_subscription_ack_deadline_seconds
  dispatcher_subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
  inspector_service_timeout_seconds                  = var.inspector_service_timeout_seconds
  inspector_subscription_ack_deadline_seconds        = var.inspector_subscription_ack_deadline_seconds
  inspector_subscription_message_retention_duration  = var.inspector_subscription_message_retention_duration
  retain_inspector_pubsub_messages      = var.retain_inspector_pubsub_messages
}

# Assign permissions for the service accounts used in this solution on the data projects when using standard mode.
# For this to run, the terraform service account must have permissions to set IAM policies on each data project. You can achieve this by running scripts/prepare_terraform_service_account_on_data_projects.sh "data-project-1" "data-project-2".
# If you can't grant the terraform account such access, this step can also be done via scripts/prepare_data_projects_for_standard_mode.sh by an authorized user
module "data_projects_permissions_for_bq_inspection_stack" {
  source = "./modules/data-project-permissions-for-bq-inspection-stack"

  // deploy the inspection stack only if we are not in bq auto_dlp_mode (i.e. bq inspection stack)
  count  = local.is_auto_dlp_mode? 0 : length(local.data_projects)

  target_project                          = local.data_projects[count.index]
  sa_bq_remote_func_get_policy_tags_email = module.bq-remote-func-get-table-policy-tags.cloud_function_sa_email
  sa_dlp_email                            = local.dlp_service_account_email
  sa_inspection_dispatcher_email          = module.bq-inspection-stack[0].sa_inspection_dispatcher_email
  sa_inspector_email                      = module.bq-inspection-stack[0].sa_inspector_email
  sa_tagger_email                         = google_service_account.sa_tagger.email
  sa_tagging_dispatcher_email             = google_service_account.sa_tagging_dispatcher.email
}

resource "google_storage_bucket_iam_member" "gcs_flags_bucket_iam_member_sa_inspector_email" {
  // deploy the inspection stack only if we are not in bq auto_dlp_mode (i.e. bq inspection stack)
  count  = local.is_auto_dlp_mode ? 0 : 1

  bucket = google_storage_bucket.gcs_flags_bucket.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.bq-inspection-stack[0].sa_inspector_email}"
}

resource "google_storage_bucket_iam_member" "gcs_flags_bucket_iam_member_sa_inspection_dispatcher_email" {
  // deploy the inspection stack only if we are not in bq auto_dlp_mode (i.e. bq inspection stack)
  count  = local.is_auto_dlp_mode ? 0 : 1

  bucket = google_storage_bucket.gcs_flags_bucket.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.bq-inspection-stack[0].sa_inspection_dispatcher_email}"
}