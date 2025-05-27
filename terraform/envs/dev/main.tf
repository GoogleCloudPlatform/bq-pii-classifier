/*
Deploy the modules in the following waves for dependency resolution:
- apis, dlp (with dlp tags set to blank)
- tags, dlp (with dlp tags linked to the output of the tags module)
- iam_on_host_project, iam_on_publishing_project, annotations-solution, org_iam, data_folders_iam,
 */

data google_project "gcp_host_project" {
  project_id = var.application_project
}

locals {
  dlp_service_account_email = "service-${data.google_project.gcp_host_project.number}@dlp-api.iam.gserviceaccount.com"
}

module "apis" {
  source = "../../modules/terraform_00_apis"

  application_project = var.application_project
  publishing_project  = var.publishing_project
}

module "dlp" {
  source = "../../modules/terraform_04_dlp"

  org_id                             = var.org_id
  application_project                = var.application_project
  publishing_project                 = var.publishing_project
  data_region                        = var.data_region
  source_data_regions                = var.source_data_regions
  terraform_data_deletion_protection = var.terraform_data_deletion_protection

  # tags for dlp
  dlp_tag_high_sensitivity_value_namespaced_name     = module.tags.dlp_tag_high_sensitivity_id
  dlp_tag_moderate_sensitivity_value_namespaced_name = module.tags.dlp_tag_moderate_sensitivity_id
  dlp_tag_low_sensitivity_value_namespaced_name      = module.tags.dlp_tag_low_sensitivity_id

  deploy_dlp_inspection_template_to_global_region = var.deploy_dlp_inspection_template_to_global_region

  built_in_info_types = var.built_in_info_types

  custom_info_types_dictionaries = var.custom_info_types_dictionaries

  custom_info_types_regex = var.custom_info_types_regex

  dlp_bq_discovery_configurations = var.dlp_bq_discovery_configurations

  dlp_gcs_discovery_configurations = var.dlp_gcs_discovery_configurations

  depends_on = [module.apis]
}

module "tags" {
  source = "../../modules/terraform_03_tags"

  org_id                             = var.org_id
  dlp_tag_sensitivity_level_key_name = var.dlp_tag_sensitivity_level_key_name
  ignore_dlp_sensitivity_key_name    = var.ignore_dlp_sensitivity_key_name

  dlp_tag_sensitivity_level_key_iam_tag_user_principles = ["serviceAccount:${local.dlp_service_account_email}"]
  ignore_dlp_sensitivity_key_iam_tag_user_principles = []
}

module "iam_on_host_project" {
  source = "../../modules/terraform_01_iam_host_project"

  application_project = var.application_project

  depends_on = [module.apis]
}

module "iam_on_publishing_project" {
  source = "../../modules/terraform_02_iam_publishing_project"

  application_project = var.application_project
  publishing_project  = var.publishing_project

  depends_on = [module.apis, module.iam_on_host_project]
}

module "annotations-solution" {
  source = "../../modules/terraform_05_annotations_infra"

  application_project = var.application_project
  publishing_project  = var.publishing_project
  data_region         = var.data_region
  source_data_regions = var.source_data_regions
  compute_region      = var.compute_region
  terraform_data_deletion_protection = var.terraform_data_deletion_protection
  services_container_image_name = var.services_container_image_name

  # Linked variables. One can also omit and use the defaults assuming that they are in-sync across modules
  dlp_dataset_name = module.dlp.dlp_results_dataset
  application_service_account_name = module.iam_on_host_project.sa_application_name
  tagger_bq_service_account_name = module.iam_on_host_project.sa_tagger_bq_name
  tagger_gcs_service_account_name = module.iam_on_host_project.sa_tagger_gcs_name
  dlp_for_bq_pubsub_topic_name     = module.dlp.dlp_bq_notifications_topic
  dlp_for_gcs_pubsub_topic_name    = module.dlp.dlp_gcs_notifications_topic

  classification_taxonomy = var.classification_taxonomy

  depends_on = [module.iam_on_host_project]
}


module "org_iam" {
  source = "../../modules/terraform_06_iam_org_level"

  org_id                          = var.org_id
  application_project             = var.application_project

  # Linked variables. One can also omit and use the defaults assuming that they are in-sync across modules
  tagger_bq_service_account_name = module.iam_on_host_project.sa_tagger_bq_name
  tagger_gcs_service_account_name = module.iam_on_host_project.sa_tagger_gcs_name

  depends_on = [module.iam_on_host_project, module.dlp, module.annotations-solution]
}

module "data_folders_iam" {
  source = "../../modules/terraform_07_iam_folder_level"

  org_id                          = var.org_id
  application_project             = var.application_project

  # use same folder ids configured in the DLP module dlp_bq_discovery_configurations & dlp_bq_discovery_configurations
  dlp_gcs_configurations_folders = module.dlp.dlp_gcs_folders
  dlp_bq_configurations_folders = module.dlp.dlp_bq_folders

  # Linked variables. One can also omit and use the defaults assuming that they are in-sync across modules
  tagger_bq_service_account_name   = module.iam_on_host_project.sa_tagger_bq_name
  tagger_gcs_service_account_name  = module.iam_on_host_project.sa_tagger_gcs_name
  tagger_bq_custom_role_id = module.org_iam.tagger_bq_custom_role_id
  tagger_gcs_custom_role_id = module.org_iam.tagger_gcs_custom_role_id

  depends_on = [module.iam_on_host_project, module.org_iam, module.dlp, module.annotations-solution]
}

