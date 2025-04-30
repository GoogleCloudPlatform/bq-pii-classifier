########################################################################################################################
#                                          STACK-SPECIFIC VARIABLES
########################################################################################################################

variable "tagger_bq_service_account_name" {
  type = string
  default = "annotations-bq"
}

variable "tagger_bq_custom_role_id" {
  type        = string
  description = "The custom role ID to be created at the organization level for the BQ Tagger service."
  default     = "AnnotationsSolutionBQTaggerServiceRole"
}

########################################################################################################################
#                                          DATA & LOCALS
########################################################################################################################

locals {
  tagger_bq_service_account_email = "${var.tagger_bq_service_account_name}@${var.application_project}.iam.gserviceaccount.com"
}

########################################################################################################################
#                                          CUSTOM ROLES
########################################################################################################################

resource "google_organization_iam_custom_role" "custom_role_tagger_bq" {
  org_id      = var.org_id
  role_id     = var.tagger_bq_custom_role_id
  title       = "CR for the GCP Annotations solution to annotate BQ tables"
  description = "Allows viewing and updating storage buckets metadata."

  permissions = [
    "bigquery.tables.get", # get table metadata (e.g. labels, schema and policy tags) (not table data)
    "bigquery.tables.update", #  update table metadata (e.g. labels, schema and policy tags) (not table data)
    "bigquery.tables.setCategory", # to apply policy tags to columns
    "datacatalog.taxonomies.get", # to get existing policy tag names and report them
    "bigquery.datasets.get", # get dataset location (to determine regional policy tags)
  ]
  // replace this custom role with "roles/bigquery.dataOwner" and "" in case it can't be created

  stage = "GA"
}

########################################################################################################################
#                                          IAM BINDINGS
########################################################################################################################

// Tagger needs to read column profiles saved by the org-level dlp discovery configuration
resource "google_organization_iam_member" "iam_member_tagger_bq_sa_column_profiles_reader" {
  org_id = var.org_id
  role   = "roles/dlp.columnDataProfilesReader"
  member = "serviceAccount:${local.tagger_bq_service_account_email}"
}
########################################################################################################################
#                                            OUTPUT
########################################################################################################################

output "tagger_bq_custom_role_id" {
  value = google_organization_iam_custom_role.custom_role_tagger_bq.role_id
}