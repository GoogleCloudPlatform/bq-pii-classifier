########################################################################################################################
#                                          STACK-SPECIFIC VARIABLES
########################################################################################################################

variable "tagger_gcs_service_account_name" {
  type = string
  default = "annotations-gcs"
}

variable "dlp_gcs_configurations_folders" {
  type = list(number)
  description = "List of GCP folder IDs to be scanned by DLP discovery service for GCS"
}

variable "tagger_gcs_custom_role_id" {
  type        = string
  description = "Existing custom role ID for the GCS Tagger service."
  default     = "AnnotationsSolutionGcsTaggerServiceRole"
}

########################################################################################################################
#                                          DATA & LOCALS
########################################################################################################################

locals {
  tagger_gcs_service_account_email = "${var.tagger_gcs_service_account_name}@${var.application_project}.iam.gserviceaccount.com"
  tagger_gcs_custom_role_resource_name  = "organizations/${var.org_id}/roles/${var.tagger_gcs_custom_role_id}"
}


########################################################################################################################
#                                          Modules
########################################################################################################################


// This module assigns roles and permissions to service accounts used in this solution on data FOLDER levels (and not the host project)
// The Terraform service account needs certain org/folder levels roles to be able to deploy these. If you can't grant such roles, replicate this particular module in your org CICD pipelines.
// Run `scripts/prepare_terraform_service_account_on_org.sh <org id>` to grant permissions for Terraform to assign roles on org and folder level
module "gcs-discovery-stack-folder-permissions" {
  source = "./modules/gcs-discovery-stack-folder-permissions"

  // deploy once per folder
  count = length(var.dlp_gcs_configurations_folders)

  dlp_config_folder_id  = var.dlp_gcs_configurations_folders[count.index]
  tagger_sa_email       = local.tagger_gcs_service_account_email
  dlp_service_sa_email  = local.dlp_service_account_email
  tagger_custom_role_id = local.tagger_gcs_custom_role_resource_name
}



