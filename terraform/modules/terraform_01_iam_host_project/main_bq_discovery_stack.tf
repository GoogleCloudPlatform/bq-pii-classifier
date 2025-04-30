########################################################################################################################
#                                           Locals
########################################################################################################################

locals {

  sa_tagger_bq_roles = [
    "roles/artifactregistry.reader", # to read container image for the service
    "roles/datacatalog.viewer", # to "get" solution-owned taxonomies created in that project
    "roles/storage.objectAdmin", # to read and write data to resources buckets (flags, resources, etc)
  ]
}

########################################################################################################################
#                                            Service Accounts
########################################################################################################################

resource "google_service_account" "sa_tagger_bq" {
  project      = var.application_project
  account_id   = var.tagger_bq_service_account_name
  display_name = "Data annotations service for BigQuery"
}


########################################################################################################################
#                                            IAM bindings
########################################################################################################################

resource "google_project_iam_member" "sa_tagger_bq_roles_binding" {
  count = length(local.sa_tagger_bq_roles)
  project = var.application_project
  role    = local.sa_tagger_bq_roles[count.index]
  member  = "serviceAccount:${google_service_account.sa_tagger_bq.email}"
}

// push subscription SA needs to push to tagger SA
resource "google_service_account_iam_member" "sa_tagger_bq_account_user_sa_tagger_tasks" {
  service_account_id = google_service_account.sa_tagger_bq.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.sa_application.email}"
}
