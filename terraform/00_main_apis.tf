
locals {
  apis_list = [
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "datastore.googleapis.com",
    "firestore.googleapis.com",
    "workflows.googleapis.com",
    "datacatalog.googleapis.com",
    "dlp.googleapis.com"
  ]
}

resource "google_project_service" "enable_apis" {
  count = length(local.apis_list)
  project = var.project
  service = local.apis_list[count.index]

  disable_on_destroy = false
  disable_dependent_services = true
}






