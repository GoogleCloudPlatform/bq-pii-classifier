
############################### ORG LEVEL SETUP ####################
#######################      deploy once per org      ################

resource "google_organization_iam_custom_role" "custom_role_tagger" {
  org_id      = var.org_id
  role_id     = "AnnotationsSolutionBQTaggerServiceRole"
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

// Tagger needs to read column profiles saved by the org-level dlp discovery configuration
resource "google_organization_iam_member" "iam_member_tagger_sa_column_profiles_reader" {
  org_id = var.org_id
  role   = "roles/dlp.columnDataProfilesReader"
  member = "serviceAccount:${var.tagger_sa_email}"
}
