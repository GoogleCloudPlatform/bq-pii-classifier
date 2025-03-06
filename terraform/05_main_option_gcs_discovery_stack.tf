### DLP for GCS modules

module "gcs-discovery-stack" {

  // deploy it only if the GCS_DISCOVERY is selected
  count = contains(var.supported_stacks, "GCS_DISCOVERY")? 1: 0

  source = "./stacks/gcs-discovery-stack"

  dlp_gcs_scan_org_id = var.dlp_gcs_scan_org_id
  dlp_gcs_scan_folder_id = var.dlp_gcs_scan_folder_id
  image_name = var.image_name
  bq_results_dataset = google_bigquery_dataset.results_dataset.dataset_id
  compute_region = var.compute_region
  data_region = var.data_region
  dispatcher_service_timeout_seconds = var.dispatcher_service_timeout_seconds
  dlp_inspection_templates_ids_list = local.dlp_inspection_templates_ids_list
  gar_docker_repo_name = var.gar_docker_repo_name
  gcs_flags_bucket_name = google_storage_bucket.gcs_flags_bucket.name
  project = var.project
  tagger_service_timeout_seconds = var.tagger_service_timeout_seconds
  dispatcher_subscription_ack_deadline_seconds       = var.dispatcher_subscription_ack_deadline_seconds
  dispatcher_subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration
  info_type_map                                      = local.info_types_map
  is_dry_run_labels                                  = var.is_dry_run_labels
  tagger_subscription_ack_deadline_seconds           = var.tagger_subscription_ack_deadline_seconds
  tagger_subscription_message_retention_duration     = var.tagger_subscription_message_retention_duration
  dlp_service_account_email                          = local.dlp_service_account_email
  source_data_regions                                = var.source_data_regions
  dlp_gcs_bq_results_table_name = var.dlp_gcs_bq_results_table_name
  dlp_gcs_bucket_name_regex = var.dlp_gcs_bucket_name_regex
  dlp_gcs_create_configuration_in_paused_state = var.dlp_gcs_create_configuration_in_paused_state
  dlp_gcs_included_bucket_attributes = var.dlp_gcs_included_bucket_attributes
  dlp_gcs_included_object_attributes = var.dlp_gcs_included_object_attributes
  dlp_gcs_project_id_regex = var.dlp_gcs_project_id_regex
  dlp_gcs_reprofile_on_data_change = var.dlp_gcs_reprofile_on_data_change
  dlp_gcs_reprofile_on_inspection_template_update = var.dlp_gcs_reprofile_on_inspection_template_update
  sa_tagger_gcs = var.sa_tagger_gcs
  sa_tagger_gcs_tasks = var.sa_tagger_gcs_tasks
  sa_tagging_dispatcher_gcs = var.sa_tagging_dispatcher_gcs
  sa_tagging_dispatcher_gcs_tasks = var.sa_tagging_dispatcher_gcs_tasks
  tagger_gcs_pubsub_sub = var.tagger_gcs_pubsub_sub
  tagger_gcs_pubsub_topic = var.tagger_gcs_pubsub_topic
  tagger_gcs_service_name = var.tagger_gcs_service_name
  tagging_dispatcher_gcs_pubsub_sub = var.tagging_dispatcher_gcs_pubsub_sub
  tagging_dispatcher_gcs_pubsub_topic = var.tagging_dispatcher_gcs_pubsub_topic
  tagging_dispatcher_gcs_service_name = var.tagging_dispatcher_gcs_service_name
  bq_remote_func_get_buckets_metadata = var.bq_remote_func_get_buckets_metadata
  sa_bq_remote_func_get_buckets_metadata = var.sa_bq_remote_func_get_buckets_metadata
  gcs_existing_labels_regex = var.gcs_existing_labels_regex
  dispatcher_service_max_cpu = var.dispatcher_service_max_cpu
  dispatcher_service_max_memory = var.dispatcher_service_max_memory
  retain_dlp_tagger_pubsub_messages = var.retain_dlp_tagger_pubsub_messages
  sa_workflows_gcs = var.sa_workflows_gcs
  workflows_gcs_description = var.workflows_gcs_description
  workflows_gcs_name = var.workflows_gcs_name
  bq_view_run_summary = google_bigquery_table.view_run_summary.table_id
  logging_table_name = google_bigquery_table.logging_table.table_id
  terraform_data_deletion_protection = var.terraform_data_deletion_protection

  depends_on = [google_project_service.enable_apis]
}

// This module assigns roles and permissions to service accounts used in this solution on FOLDER AND ORG levels (and not the host project)
// The Terraform service account needs certain org/folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles on org and folder level
module "data-folder-permissions-for-gcs-discovery-stack" {

  // deploy it only if the GCS_DISCOVERY is selected
  count = contains(var.supported_stacks, "GCS_DISCOVERY")? 1: 0

  source = "./modules/org-and-folder-permissions-for-gcs-discovery-stack"

  dlp_config_org_id = var.dlp_gcs_scan_org_id
  dlp_config_folder_id = var.dlp_gcs_scan_folder_id

  # "service-${dlp scan config host project number}@dlp-api.iam.gserviceaccount.com"
  dlp_service_sa_email = local.dlp_service_account_email
  # <var.sa_tagging_dispatcher_gcs>@<host project name>.iam.gserviceaccount.com. Default: tag-dispatcher-gcs@<host project name>.iam.gserviceaccount.com
  dispatcher_sa_email = module.gcs-discovery-stack[0].dispatcher_sa_email
  # <var.sa_tagger_gcs>@<host project name>.iam.gserviceaccount.com. Default: tagger-gcs@<host project name>.iam.gserviceaccount.com
  tagger_sa_email = module.gcs-discovery-stack[0].tagger_sa_email
  # <var.sa_bq_remote_func_get_buckets_metadata>@<host project name>.iam.gserviceaccount.com. Default: sa-func-get-buckets-metadata@<host project name>.iam.gserviceaccount.com
  func_get_buckets_metadata_sa_email = module.gcs-discovery-stack[0].func_get_buckets_metadata_sa_email

  depends_on = [module.gcs-discovery-stack]
}
