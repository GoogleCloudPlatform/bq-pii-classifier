/*
Deployment notes:
- There is a dead-lock between {creating new tags and assigning IAM roles to them} and {creating DLP configs & force-creation of dlp service accounts}
- This corresponds to the modules tags and dlp
- The dead-lock happens we need to create the dlp configs (that is in turn using the tags) to force-create the dlp SA, but we also need to grant access to the SA on the tags
- To solve it, deploy on the following waves:
    -- Wave 1:
        -- set apply_tags in both GCS and BQ dlp configs to false
        -- set create_configuration_in_paused_state in both GCS and BQ dlp configs to true
        -- set the dlp.dlp_tag_* variables to empty strings
        -- apply terraform: this will create the configs without the tags, so that the DLP SA doesn't need IAM roles on them
    -- Wave 2:
        -- set apply_tags in both GCS and BQ dlp configs to true (if intended)
        -- set create_configuration_in_paused_state in both GCS and BQ dlp configs to false (if intended)
        -- map the dlp.dlp_tag_* variables to module.project_tags.dlp_tag_*
        -- apply terraform: this will grant IAM roles to the DLP SA on the tags and reference the tags in the config
 */

module "apis" {
  source = "../../modules/terraform_00_apis"

  application_project = var.application_project
  publishing_project  = var.publishing_project
}

// org-level tags for folder-level dlp configs
module "org_tags" {
  source = "../../modules/terraform_03_tags"

  parent                             = "organizations/${var.org_id}"
  dlp_tag_sensitivity_level_key_name = var.dlp_tag_sensitivity_level_key_name
  ignore_dlp_sensitivity_key_name    = var.ignore_dlp_sensitivity_key_name

  // only DLP service accounts (across all configs)  should be able to tag/untag resources with the DLP sensitivity tags (unless desired otherwise)
  dlp_tag_sensitivity_level_key_iam_tag_user_principles = [for x in module.dlp.dlp_service_account_emails: "serviceAccount:${x}"]
  // TODO: all users should be able to use the ignore/bypass tag. Set to an equivalent of "all users"
  ignore_dlp_sensitivity_key_iam_tag_user_principles = []
}

module "dlp" {
  source = "../../modules/terraform_04_dlp"

  application_project                = var.application_project
  publishing_project                 = var.publishing_project
  data_region                        = var.data_region
  source_data_regions                = var.source_data_regions
  terraform_data_deletion_protection = var.terraform_data_deletion_protection

  # tags for dlp
  dlp_tag_high_sensitivity_value_namespaced_name     = module.org_tags.dlp_tag_high_sensitivity_namespaced_name
  dlp_tag_moderate_sensitivity_value_namespaced_name = module.org_tags.dlp_tag_moderate_sensitivity_namespaced_name
  dlp_tag_low_sensitivity_value_namespaced_name      = module.org_tags.dlp_tag_low_sensitivity_namespaced_name

  deploy_dlp_inspection_template_to_global_region = var.deploy_dlp_inspection_template_to_global_region

  built_in_info_types = var.built_in_info_types

  custom_info_types_dictionaries = var.custom_info_types_dictionaries

  custom_info_types_regex = var.custom_info_types_regex

  dlp_bq_discovery_configurations = var.dlp_bq_discovery_configurations

  dlp_gcs_discovery_configurations = var.dlp_gcs_discovery_configurations

  depends_on = [module.apis]
}


module "iam_on_host_project" {
  source = "../../modules/terraform_01_iam_host_project"

  application_project = var.application_project
  dlp_service_agents_emails = module.dlp.dlp_service_account_emails

  depends_on = [module.apis]
}

module "iam_on_publishing_project" {
  source = "../../modules/terraform_02_iam_publishing_project"

  application_project = var.application_project
  publishing_project  = var.publishing_project
  dlp_service_agents_emails = module.dlp.dlp_service_account_emails

  depends_on = [module.apis, module.iam_on_host_project]
}

module "annotations-solution" {
  source = "../../modules/terraform_05_annotations_infra"

  application_project                = var.application_project
  publishing_project                 = var.publishing_project
  data_region                        = var.data_region
  source_data_regions                = var.source_data_regions
  compute_region                     = var.compute_region
  terraform_data_deletion_protection = var.terraform_data_deletion_protection
  services_container_image_name      = var.services_container_image_name

  # Linked variables. One can also omit and use the defaults assuming that they are in-sync across modules
  dlp_dataset_name                 = module.dlp.dlp_results_dataset
  application_service_account_name = module.iam_on_host_project.sa_application_name
  tagger_bq_service_account_name   = module.iam_on_host_project.sa_tagger_bq_name
  tagger_gcs_service_account_name  = module.iam_on_host_project.sa_tagger_gcs_name
  dlp_for_bq_pubsub_topic_name     = module.dlp.dlp_bq_notifications_topic
  dlp_for_gcs_pubsub_topic_name    = module.dlp.dlp_gcs_notifications_topic

  classification_taxonomy = var.classification_taxonomy

  depends_on = [module.iam_on_host_project]
}


module "org_iam" {
  source = "../../modules/terraform_06_iam_org_level"

  org_id                    = var.org_id
  application_project       = var.application_project
  dlp_service_account_email = module.dlp.application_project_dlp_service_account_email

  # Linked variables. One can also omit and use the defaults assuming that they are in-sync across modules
  tagger_bq_service_account_name  = module.iam_on_host_project.sa_tagger_bq_name
  tagger_gcs_service_account_name = module.iam_on_host_project.sa_tagger_gcs_name

  depends_on = [module.iam_on_host_project, module.dlp]
}

module "data_folders_iam" {
  source = "../../modules/terraform_07_iam_folder_level"

  org_id              = var.org_id
  application_project = var.application_project

  # use same folder ids configured in the DLP module dlp_bq_discovery_configurations & dlp_bq_discovery_configurations
  dlp_gcs_configurations_folders = module.dlp.dlp_gcs_folders
  dlp_bq_configurations_folders  = module.dlp.dlp_bq_folders

  dlp_service_account_email        = module.dlp.application_project_dlp_service_account_email
  tagger_bq_service_account_email  = module.iam_on_host_project.sa_tagger_bq_email
  tagger_gcs_service_account_email = module.iam_on_host_project.sa_tagger_gcs_email

  tagger_bq_custom_role_id  = module.org_iam.tagger_bq_custom_role_id
  tagger_gcs_custom_role_id = module.org_iam.tagger_gcs_custom_role_id

  depends_on = [module.iam_on_host_project, module.org_iam, module.dlp]
}

