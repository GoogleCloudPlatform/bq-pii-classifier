module "bq-discovery-stack" {

  // deploy the stack one time if the configurations list is not empty
  count = length(var.dlp_bq_discovery_configurations) == 0 ? 0 : 1

  source = "./stacks/bq-discovery-stack"

  dlp_bq_discovery_configurations                = var.dlp_bq_discovery_configurations
  bigquery_dataset_name                          = google_bigquery_dataset.results_dataset.dataset_id
  dlp_service_account_email                      = local.dlp_service_account_email
  auto_dlp_results_table_name                    = var.auto_dlp_results_table_name
  bq_existing_labels_regex                       = var.bq_existing_labels_regex
  bq_remote_func_get_policy_tags_name            = var.bq_remote_func_get_policy_tags_name
  bq_view_run_summary                            = google_bigquery_table.view_run_summary.table_id
  classification_taxonomy                        = var.classification_taxonomy
  compute_region                                 = var.compute_region
  data_catalog_taxonomy_activated_policy_types   = var.data_catalog_taxonomy_activated_policy_types
  data_region                                    = var.data_region
  datastore_database_name                        = var.datastore_database_name
  default_domain_name                            = var.default_domain_name
  dlp_bq_scan_org_id                             = var.org_id
  dlp_inspection_templates_ids_list              = local.dlp_inspection_templates_ids_list
  domain_mapping                                 = var.domain_mapping
  gar_docker_repo_name                           = var.gar_docker_repo_name
  gcs_flags_bucket_name                          = google_storage_bucket.gcs_flags_bucket.id
  iam_mapping                                    = var.iam_mapping
  is_dry_run_labels                              = var.is_dry_run_labels
  is_dry_run_tags                                = var.is_dry_run_tags
  logging_table_name                             = google_bigquery_table.logging_table_cloud_run.table_id
  project                                        = var.application_project
  publishing_project                             = var.publishing_project
  promote_dlp_other_matches                      = var.promote_dlp_other_matches
  retain_dlp_tagger_pubsub_messages              = var.retain_dlp_tagger_pubsub_messages
  sa_bq_remote_func_get_policy_tags              = var.sa_bq_remote_func_get_policy_tags
  tagger_bq_service_account_name                 = var.tagger_bq_service_account_name
  application_service_account_name               = var.application_service_account_name
  source_data_regions                            = var.source_data_regions
  tagger_pubsub_sub                              = var.tagger_pubsub_sub
  tagger_pubsub_topic                            = var.tagger_pubsub_topic
  tagger_service_name                            = var.tagger_service_name
  tagger_service_timeout_seconds                 = var.tagger_service_timeout_seconds
  tagger_subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  tagger_subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
  taxonomy_name_suffix                           = var.taxonomy_name_suffix
  terraform_data_deletion_protection             = var.terraform_data_deletion_protection
  workflows_bq_description                       = var.workflows_bq_description
  workflows_bq_name                              = var.workflows_bq_name
  image_name                                     = var.image_name
  resources_bucket_name                          = google_storage_bucket.gcs_solution_resources.name
  info_type_map_file_path = "gs://${google_storage_bucket.gcs_solution_resources.name}/${google_storage_bucket_object.info_type_map_file.name}"

  # tags
  dlp_tag_high_sensitivity_id     = google_tags_tag_value.dlp_high_sensitivity_value.namespaced_name
  dlp_tag_moderate_sensitivity_id = google_tags_tag_value.dlp_moderate_sensitivity_value.namespaced_name
  dlp_tag_low_sensitivity_id = google_tags_tag_value.dlp_low_sensitivity_value.namespaced_name

  # Dispatcher Cloud Batch settings
  dispatcher_cloud_batch_cpu_millis               = var.dispatcher_cloud_batch_cpu_millis
  dispatcher_cloud_batch_memory_mib               = var.dispatcher_cloud_batch_memory_mib
  dispatcher_cloud_batch_max_run_duration_seconds = var.dispatcher_cloud_batch_max_run_duration_seconds
  dispatcher_pubsub_client_config = var.dispatcher_pubsub_client_config

  # Tagger Cloud Run scalability settings
  tagger_service_max_containers             = var.tagger_bq_service_max_containers
  tagger_service_max_cpu                    = var.tagger_bq_service_max_cpu
  tagger_service_max_memory                 = var.tagger_bq_service_max_memory
  tagger_service_max_requests_per_container = var.tagger_bq_service_max_requests_per_container

  depends_on = [
    google_project_service.enable_apis,
    google_project_service.enable_apis_on_publishing_project,
    google_bigquery_table.logging_table_cloud_run
  ]
}

// This module creates granular custom roles and assigns roles and permissions to service accounts used in this solution on ORG levels (and not the host project)
// The Terraform service account needs certain org/folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles on org and folder level
module "bq-discovery-stack-org-permissions" {
  source = "./modules/bq-discovery-stack-org-permissions"

  // deploy the stack one time if the configurations list is not empty
  count = length(var.dlp_bq_discovery_configurations) == 0 ? 0 : 1

  org_id = var.org_id
  # default: tagger-bq@<host project id>.iam.gserviceaccount.com
  tagger_sa_email = local.sa_tagger_bq_email

  depends_on = [module.bq-discovery-stack]
}

// This module assigns roles and permissions to service accounts used in this solution on data FOLDER levels (and not the host project)
// The Terraform service account needs certain org/folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles on org and folder level
module "bq-discovery-stack-folder-permissions" {
  source = "./modules/bq-discovery-stack-folder-permissions"

  // deploy once per folder
  count = length(var.dlp_bq_discovery_configurations)


  dlp_config_folder_id = var.dlp_bq_discovery_configurations[count.index].folder_id
  # "service-${dlp scan config host project number}@dlp-api.iam.gserviceaccount.com"
  dlp_service_sa_email = local.dlp_service_account_email
  # default: sa-func-get-policy-tags@<host project id>.iam.gserviceaccount.com
  sa_bq_remote_func_get_policy_tags_email = module.bq-discovery-stack[0].sa_bq_remote_func_get_policy_tags_email
  # <var.sa_tagger_bq>@<host project name>.iam.gserviceaccount.com. Default: tagger@<host project name>.iam.gserviceaccount.com
  sa_tagger_email       = local.sa_tagger_bq_email
  tagger_custom_role_id = module.bq-discovery-stack-org-permissions[0].tagger_custom_role_id

  depends_on = [module.gcs-discovery-stack-org-permissions]

}