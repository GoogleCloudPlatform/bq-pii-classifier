# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam#google_project_iam_member


############## Service Accounts ######################################

resource "google_service_account" "sa_tagging_dispatcher" {
  project = var.project
  account_id = var.sa_tagging_dispatcher
  display_name = "Runtime SA for Tagging Dispatcher service"
}

resource "google_service_account" "sa_tagger" {
  project = var.project
  account_id = var.sa_tagger
  display_name = "Runtime SA for Tagger service"
}

resource "google_service_account" "sa_tagging_dispatcher_tasks" {
  project = var.project
  account_id = var.sa_tagging_dispatcher_tasks
  display_name = "To authorize PubSub Push requests to Tagging Dispatcher Service"
}

resource "google_service_account" "sa_tagger_tasks" {
  project = var.project
  account_id = var.sa_tagger_tasks
  display_name = "To authorize PubSub Push requests to Tagger Service"
}

############## Service Accounts Access ################################

# Use google_project_iam_member because it's Non-authoritative.
# It Updates the IAM policy to grant a role to a new member.
# Other members for the role for the project are preserved.


#### Dispatcher Tasks Permissions ###

resource "google_service_account_iam_member" "sa_tagging_dispatcher_account_user_sa_dispatcher_tasks" {
  service_account_id = google_service_account.sa_tagging_dispatcher.name
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.sa_tagging_dispatcher_tasks.email}"
}

#### Dispatcher SA Permissions ###

# Grant sa_dispatcher access to submit query jobs
resource "google_project_iam_member" "sa_tagging_dispatcher_bq_job_user" {
  project = var.project
  role = "roles/bigquery.jobUser"
  member = "serviceAccount:${google_service_account.sa_tagging_dispatcher.email}"
}

// tagging dispatcher needs to read data from dlp results table and views created inside the solution-managed dataset
// e.g. listing tables to be tagged
resource "google_bigquery_dataset_access" "sa_tagging_dispatcher_bq_dataset_reader" {
  dataset_id    = var.bq_results_dataset
  role          = "roles/bigquery.dataViewer"
  user_by_email = google_service_account.sa_tagging_dispatcher.email
}



#### Tagger Tasks SA Permissions ###

resource "google_service_account_iam_member" "sa_tagger_account_user_sa_tagger_tasks" {
  service_account_id = google_service_account.sa_tagger.name
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.sa_tagger_tasks.email}"
}

#### Tagger SA Permissions ###

resource "google_project_iam_custom_role" "tagger-role" {
  project = var.project
  role_id = var.tagger_role
  title = var.tagger_role
  description = "Used to grant permissions to sa_tagger"
  permissions = [
    "bigquery.tables.setCategory",
    "datacatalog.taxonomies.get"]
}

resource "google_project_iam_member" "sa_tagger_role" {
  project = var.project
  role = google_project_iam_custom_role.tagger-role.name
  member = "serviceAccount:${google_service_account.sa_tagger.email}"
}

// tagger needs to read data from views created inside the solution-managed dataset
// e.g. dlp results view
resource "google_bigquery_dataset_access" "sa_tagger_bq_dataset_reader" {
  dataset_id    = var.bq_results_dataset
  role          = "roles/bigquery.dataViewer"
  user_by_email = google_service_account.sa_tagger.email
}

# to submit query jobs
resource "google_project_iam_member" "sa_tagger_bq_job_user" {
  project = var.project
  role = "roles/bigquery.jobUser"
  member = "serviceAccount:${google_service_account.sa_tagger.email}"
}


############## DLP Service Account ################################################

resource "google_project_iam_member" "dlp_sa_binding" {
  project = var.project
  role = "roles/datacatalog.categoryFineGrainedReader"
  member = "serviceAccount:${var.dlp_service_account}"
}

############## Data Catalog Taxonomies Permissions ################################


locals {

  # For each parent tag: omit the tag_id and lookup the list of IAM members to grant access to
  parent_tags_with_members_list = [for parent_tag in var.taxonomy_parent_tags:
    {
      policy_tag_name = lookup(parent_tag, "id")
      # lookup the iam_mapping variable with the key <domain>_<classification>
      # parent_tag.display_name is the classification

      iam_members = lookup(
      lookup(var.iam_mapping, lookup(parent_tag, "domain", "NA")),
      lookup(parent_tag, "display_name", "NA"),
      ["IAM_MEMBERS_LOOKUP_FAILED"]
      )
//      iam_members = lookup(var.iam_mapping,
//      "${lookup(parent_tag, "domain", "NA")}_${lookup(parent_tag, "display_name", "NA")}",
//      ["IAM_MEMBERS_LOOKUP_FAILED"]
//      )

    }]

  // flatten the iam_members list inside of parent_tags_with_members_list
  iam_members_list = flatten([for entry in local.parent_tags_with_members_list:[
  for member in lookup(entry, "iam_members", "NA"):
    {
      policy_tag_name = lookup(entry, "policy_tag_name", "NA")
      iam_member = member
    }
  ]])
}

# Grant permissions for every member in the iam_members_list
resource "google_data_catalog_policy_tag_iam_member" "policy_tag_reader" {
  provider = google-beta
  count = length(local.iam_members_list)
  policy_tag = lookup(local.iam_members_list[count.index], "policy_tag_name")
  role = "roles/datacatalog.categoryFineGrainedReader"
  member = lookup(local.iam_members_list[count.index], "iam_member")
}


