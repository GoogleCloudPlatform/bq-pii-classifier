########################################################################################################################
#                                          STACK-SPECIFIC VARIABLES
########################################################################################################################

variable "tagger_bq_service_account_name" {
  type = string
}

variable "tagger_bq_custom_role_id" {
  type        = string
  description = "The custom role ID to be created at the organization level for the BQ Tagger service."
  default     = "AnnotationsSolutionBQTaggerServiceRole"
}

variable "dlp_bq_configurations_folders" {
  type = list(number)
  description = "List of GCP folder IDs to be scanned by DLP discovery service for BigQuery"
}

########################################################################################################################
#                                          DATA & LOCALS
########################################################################################################################

locals {
  tagger_bq_service_account_email = "${var.tagger_bq_service_account_name}@${var.application_project}.iam.gserviceaccount.com"
  tagger_bq_custom_role_resource_name  = "organizations/${var.org_id}/roles/${var.tagger_bq_custom_role_id}"
}

########################################################################################################################
#                                          Modules
########################################################################################################################


// This module assigns roles and permissions to service accounts used in this solution on data FOLDER levels (and not the host project)
// The Terraform service account needs certain org/folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles on org and folder level
module "bq-discovery-stack-folder-permissions" {
  source = "./modules/bq-discovery-stack-folder-permissions"
  // deploy once per folder
  count = length(var.dlp_bq_configurations_folders)

  dlp_config_folder_id = var.dlp_bq_configurations_folders[count.index]
  dlp_service_sa_email = local.dlp_service_account_email
  sa_tagger_email       = local.tagger_bq_service_account_email
  tagger_custom_role_id = local.tagger_bq_custom_role_resource_name
}