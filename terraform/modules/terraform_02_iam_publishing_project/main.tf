data google_project "gcp_host_project" {
  project_id = var.application_project
}

locals {
  dlp_service_account_email = "service-${data.google_project.gcp_host_project.number}@dlp-api.iam.gserviceaccount.com"

  cloud_logging_service_account_email = "service-${data.google_project.gcp_host_project.number}@gcp-sa-logging.iam.gserviceaccount.com"

  application_service_account_email = "${var.application_service_account_name}@${var.application_project}.iam.gserviceaccount.com"

  sa_cloud_logging_roles_on_publishing_project = [
    "roles/bigquery.dataEditor", # for log sink to route logs to bigquery
  ]

  sa_application_roles_on_publsihing_project = [
    "roles/bigquery.dataEditor", # for dispatcher to write to dispatcher_runs tables
  ]

  dlp_sa_roles_on_publishing_project = [
    "roles/bigquery.dataEditor", # for dlp to write results to bq
  ]
}


########################################################################################################################
#                                            IAM Bindings
########################################################################################################################

######### Application SA

resource "google_project_iam_member" "sa_application_roles_binding_on_publishing_project" {
  count = length(local.sa_application_roles_on_publsihing_project)
  project = var.publishing_project
  role    = local.sa_application_roles_on_publsihing_project[count.index]
  member  = "serviceAccount:${local.application_service_account_email}"
}


######### DLP SA

resource "google_project_iam_member" "sa_dlp_roles_binding_on_publishing_project" {
  count = length(local.dlp_sa_roles_on_publishing_project)
  project = var.publishing_project
  role = local.dlp_sa_roles_on_publishing_project[count.index]
  member = "serviceAccount:${local.dlp_service_account_email}"
}

######### Cloud Logging SA
resource "google_project_iam_member" "sa_cloud_logging_roles_binding_on_publishing_project" {
  count = length(local.sa_cloud_logging_roles_on_publishing_project)
  project = var.publishing_project
  role    = local.sa_cloud_logging_roles_on_publishing_project[count.index]
  member  = "serviceAccount:${local.cloud_logging_service_account_email}"
}



