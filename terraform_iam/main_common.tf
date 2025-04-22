
provider "google" {
  project                     = var.application_project
  impersonate_service_account = var.terraform_service_account_email
}

data google_project "gcp_host_project" {
  project_id = var.application_project
}

locals {
  dlp_service_account_email = "service-${data.google_project.gcp_host_project.number}@dlp-api.iam.gserviceaccount.com"

  cloud_logging_service_account_email = "service-${data.google_project.gcp_host_project.number}@gcp-sa-logging.iam.gserviceaccount.com"

  sa_application_roles_on_host_project = [
    "roles/bigquery.jobUser", # for dispatcher to run the query that reads DLP findings
    "roles/batch.agentReporter", # for dispatcher to run Cloud Batch jobs
    "roles/logging.logWriter", # for dispatcher to run Cloud Batch jobs,
    "roles/artifactregistry.reader", # for dispatcher to read container image for the service
    "roles/batch.jobsEditor", # for cloud workflows  to run batch jobs
    "roles/pubsub.publisher", # for dispatcher to publish messages to PubSub
  ]

  sa_cloud_logging_roles_on_publishing_project = [
    "roles/bigquery.dataEditor", # for log sink to route logs to bigquery
  ]

  sa_application_roles_on_publsihing_project = [
    "roles/bigquery.dataEditor", # for dispatcher to write to dispatcher_runs tables
  ]

  dlp_sa_roles_on_host_project = [
    "roles/datacatalog.categoryFineGrainedReader", # read BigQuery columns tagged by solution-managed taxonomies
  ]

  dlp_sa_roles_on_publishing_project = [
    "roles/bigquery.dataEditor", # for dlp to write results to bq
  ]
}

########################################################################################################################
#                                            Service Accounts
########################################################################################################################

resource "google_service_account" "sa_application" {
  project      = var.application_project
  account_id   = var.application_service_account_name
  display_name = "Service account to run the data annotations application components"
}


########################################################################################################################
#                                            IAM Bindings
########################################################################################################################

######### Application SA

resource "google_project_iam_member" "sa_application_roles_binding_on_host_project" {
  count = length(local.sa_application_roles_on_host_project)
  project = var.application_project
  role    = local.sa_application_roles_on_host_project[count.index]
  member  = "serviceAccount:${google_service_account.sa_application.email}"
}

resource "google_project_iam_member" "sa_application_roles_binding_on_publishing_project" {
  count = length(local.sa_application_roles_on_publsihing_project)
  project = var.publishing_project
  role    = local.sa_application_roles_on_publsihing_project[count.index]
  member  = "serviceAccount:${google_service_account.sa_application.email}"
}

# sa_application must have roles/iam.serviceAccountUser on itself for services running it can invoke each other
resource "google_service_account_iam_member" "sa_application_service_account_user" {
  service_account_id = google_service_account.sa_application.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.sa_application.email}"
}

######### DLP SA

resource "google_project_iam_member" "sa_dlp_roles_binding_on_host_project" {
  count = length(local.dlp_sa_roles_on_host_project)
  project = var.application_project
  role = local.dlp_sa_roles_on_host_project[count.index]
  member = "serviceAccount:${local.dlp_service_account_email}"
}

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



