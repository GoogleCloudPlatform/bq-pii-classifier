
locals {
  apis_list = [
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "datastore.googleapis.com",
    "firestore.googleapis.com",
    "workflows.googleapis.com",
    "datacatalog.googleapis.com",
    "dlp.googleapis.com",
    "batch.googleapis.com"
  ]

  apis_list_publishing_project = [
    "bigquery.googleapis.com",
  ]
}

resource "google_project_service" "enable_apis" {
  count = length(local.apis_list)
  project = var.application_project
  service = local.apis_list[count.index]

  disable_on_destroy = false
  disable_dependent_services = true
}

resource "google_project_service" "enable_apis_on_publishing_project" {
  count = length(local.apis_list_publishing_project)
  project = var.publishing_project
  service = local.apis_list_publishing_project[count.index]

  disable_on_destroy = false
  disable_dependent_services = true
}






