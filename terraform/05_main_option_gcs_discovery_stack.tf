### DLP for GCS modules

module "gcs-discovery-stack" {

  // deploy the stack one time if the configurations list is not empty
  count = length(var.dlp_gcs_discovery_configurations) == 0 ? 0 : 1

  source = "./stacks/gcs-discovery-stack"

  dlp_gcs_scan_org_id                            = var.org_id
  dlp_gcs_discovery_configurations               = var.dlp_gcs_discovery_configurations
  image_name                                     = var.image_name
  bq_results_dataset                             = google_bigquery_dataset.results_dataset.dataset_id
  compute_region                                 = var.compute_region
  data_region                                    = var.data_region
  dlp_inspection_templates_ids_list              = local.dlp_inspection_templates_ids_list
  gar_docker_repo_name                           = var.gar_docker_repo_name
  gcs_flags_bucket_name                          = google_storage_bucket.gcs_flags_bucket.name
  project                                        = var.application_project
  publishing_project                             = var.publishing_project
  tagger_service_timeout_seconds                 = var.tagger_service_timeout_seconds
  info_type_map                                  = local.info_types_map
  is_dry_run_labels                              = var.is_dry_run_labels
  tagger_subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  tagger_subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
  dlp_service_account_email                      = local.dlp_service_account_email
  dlp_gcs_bq_results_table_name                  = var.dlp_gcs_bq_results_table_name
  sa_tagger_gcs                                  = var.sa_tagger_gcs
  sa_tagger_gcs_tasks                            = var.sa_tagger_gcs_tasks
  sa_tagging_dispatcher_gcs                      = var.sa_tagging_dispatcher_gcs
  tagger_gcs_pubsub_sub                          = var.tagger_gcs_pubsub_sub
  tagger_gcs_pubsub_topic                        = var.tagger_gcs_pubsub_topic
  tagger_gcs_service_name                        = var.tagger_gcs_service_name
  bq_remote_func_get_buckets_metadata            = var.bq_remote_func_get_buckets_metadata
  sa_bq_remote_func_get_buckets_metadata         = var.sa_bq_remote_func_get_buckets_metadata
  gcs_existing_labels_regex                      = var.gcs_existing_labels_regex
  retain_dlp_tagger_pubsub_messages              = var.retain_dlp_tagger_pubsub_messages
  sa_workflows_gcs                               = var.sa_workflows_gcs
  workflows_gcs_description                      = var.workflows_gcs_description
  workflows_gcs_name                             = var.workflows_gcs_name
  bq_view_run_summary                            = google_bigquery_table.view_run_summary.table_id
  logging_table_name                             = google_bigquery_table.logging_table_cloud_run.table_id
  terraform_data_deletion_protection             = var.terraform_data_deletion_protection
  info_type_map_file_path                        = "gs://${google_storage_bucket.gcs_solution_resources.name}/${google_storage_bucket_object.info_type_map_file.name}"
  resources_bucket_name = google_storage_bucket.gcs_solution_resources.name

  # tags
  dlp_tag_high_sensitivity_id     = google_tags_tag_value.dlp_high_sensitivity_value.namespaced_name
  dlp_tag_moderate_sensitivity_id = google_tags_tag_value.dlp_moderate_sensitivity_value.namespaced_name
  dlp_tag_low_sensitivity_id = google_tags_tag_value.dlp_low_sensitivity_value.namespaced_name

  # Dispatcher Cloud Batch scalability settings
  dispatcher_cloud_batch_cpu_millis               = var.dispatcher_cloud_batch_cpu_millis
  dispatcher_cloud_batch_memory_mib               = var.dispatcher_cloud_batch_memory_mib
  dispatcher_cloud_batch_max_run_duration_seconds = var.dispatcher_cloud_batch_max_run_duration_seconds
  dispatcher_pubsub_client_config = var.dispatcher_pubsub_client_config

  # Tagger Cloud Run scalability settings
  tagger_service_max_containers             = var.tagger_gcs_service_max_containers
  tagger_service_max_cpu                    = var.tagger_gcs_service_max_cpu
  tagger_service_max_memory                 = var.tagger_gcs_service_max_memory
  tagger_service_max_requests_per_container = var.tagger_gcs_service_max_requests_per_container

  depends_on = [
    google_project_service.enable_apis,
    google_project_service.enable_apis_on_publishing_project,
    google_bigquery_table.logging_table_cloud_run
  ]

}

// This module creates granular custom roles and assigns roles and permissions to service accounts used in this solution on ORG levels (and not the host project)
// The Terraform service account needs certain org/folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles on org and folder level
module "gcs-discovery-stack-org-permissions" {
  source = "./modules/gcs-discovery-stack-org-permissions"

  // deploy the stack one time if the configurations list is not empty
  count = length(var.dlp_gcs_discovery_configurations) == 0 ? 0 : 1

  org_id          = var.org_id
  tagger_sa_email = local.sa_tagger_gcs_email

  depends_on = [module.gcs-discovery-stack]
}

// This module assigns roles and permissions to service accounts used in this solution on data FOLDER levels (and not the host project)
// The Terraform service account needs certain org/folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles on org and folder level
module "gcs-discovery-stack-folder-permissions" {

  source = "./modules/gcs-discovery-stack-folder-permissions"

  // deploy once per folder
  count = length(var.dlp_gcs_discovery_configurations)

  dlp_config_folder_id = var.dlp_gcs_discovery_configurations[count.index].folder_id

  # <var.sa_tagger_gcs>@<host project name>.iam.gserviceaccount.com. Default: tagger-gcs@<host project name>.iam.gserviceaccount.com
  tagger_sa_email = local.sa_tagger_gcs_email
  # "service-${dlp scan config host project number}@dlp-api.iam.gserviceaccount.com"
  dlp_service_sa_email = local.dlp_service_account_email
  # <var.sa_bq_remote_func_get_buckets_metadata>@<host project name>.iam.gserviceaccount.com. Default: sa-func-get-buckets-metadata@<host project name>.iam.gserviceaccount.com
  func_get_buckets_metadata_sa_email = module.gcs-discovery-stack[0].func_get_buckets_metadata_sa_email

  get_buckets_metadata_func_custom_role_id = module.gcs-discovery-stack-org-permissions[0].get_buckets_metadata_func_custom_role_id
  tagger_custom_role_id                    = module.gcs-discovery-stack-org-permissions[0].tagger_custom_role_id

  depends_on = [module.gcs-discovery-stack-org-permissions]
}



