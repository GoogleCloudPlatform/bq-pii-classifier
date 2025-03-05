resource "google_project_service" "enable_service_usage_api" {
  project = var.project
  service = "serviceusage.googleapis.com"

  disable_on_destroy = false
}

# Enable Cloud Build API
resource "google_project_service" "enable_cloud_build" {
  project = var.project
  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false
}

# Enables the Cloud Run API
resource "google_project_service" "run_api" {
  project = var.project
  service = "run.googleapis.com"

  disable_on_destroy = false
}

# Enable batch API to run long running dispatcher jobs
resource "google_project_service" "batch_api" {
  project = var.project
  service = "batch.googleapis.com"

  disable_on_destroy = false
}

##### Enable datastore API because the bq-remote-func-get-table-policy-tags function is using it as a cache layer

resource "google_project_service" "datastore_api" {
  service            = "datastore.googleapis.com"
  disable_on_destroy = false                     # Prevent accidental disabling during Terraform destroy
}

resource "google_project_service" "enable_workflows" {
  project = var.project
  service = "workflows.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}