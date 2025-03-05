
locals {
  apis_list = [
    "serviceusage.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "datastore.googleapis.com",
    "workflows.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "datacatalog.googleapis.com",
    "logging.googleapis.com",
    "dlp.googleapis.com"
  ]
}

resource "google_project_service" "enable_apis" {
  count = length(local.apis_list)
  project = var.project
  service = local.apis_list[count.index]

  disable_on_destroy = false
}






