
#############################################################
#                                    Data & Locals
##############################################################

# deploy 1 dlp inspection template in each source data region
locals {
  dlp_regions = var.deploy_dlp_inspection_template_to_global_region? concat(tolist(var.source_data_regions), [
    "global"
  ]) : var.source_data_regions

  created_dlp_inspection_templates = module.dlp_inspection_templates[*].created_inspection_templates

  dlp_inspection_templates_ids_list = flatten([for obj in local.created_dlp_inspection_templates : obj["ids"]])
}

#############################################################
#                                    Dlp Inspection Templates
##############################################################

module "dlp_inspection_templates" {
  count                   = length(local.dlp_regions)
  source                  = "./modules/dlp_inspection_template"
  project                 = var.application_project
  region                  = tolist(local.dlp_regions)[count.index]
  built_in_info_types = var.built_in_info_types
  custom_info_types_dictionaries = var.custom_info_types_dictionaries
  custom_info_types_regex        = var.custom_info_types_regex
}

#############################################################
#                                    Org-level Tags
##############################################################

resource "google_tags_tag_key" "dlp_sensitivity_level_key" {
  parent      = "organizations/${var.org_id}"
  short_name  = var.dlp_tag_sensitivity_level_key_name
  description = "Data sensitivity level."
}

resource "google_tags_tag_value" "dlp_high_sensitivity_value" {
  parent      = google_tags_tag_key.dlp_sensitivity_level_key.id
  short_name  = var.dlp_tag_high_sensitivity_value_name
  description = "DLP detected potential high sensitivity pii (SPII)"
}

resource "google_tags_tag_value" "dlp_moderate_sensitivity_value" {
  parent      = google_tags_tag_key.dlp_sensitivity_level_key.id
  short_name  = var.dlp_tag_moderate_sensitivity_value_name
  description = "DLP detected potential sensitive information that is not classified as high"
}

resource "google_tags_tag_value" "dlp_low_sensitivity_value" {
  parent      = google_tags_tag_key.dlp_sensitivity_level_key.id
  short_name  = var.dlp_tag_low_sensitivity_value_name
  description = "DLP didn't detect sensitive information"
}

#############################################################
#                                    BigQuery
##############################################################


resource "google_bigquery_dataset" "results_dataset" {
  project = var.publishing_project
  location = var.data_region
  dataset_id = var.bigquery_dlp_dataset_name
  description = "To store DLP results"

  delete_contents_on_destroy = !var.terraform_data_deletion_protection
}

