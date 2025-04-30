### Locals ####

locals {

  info_types_map = {
  for item in var.classification_taxonomy : item["info_type"] => {
    classification = item["classification"],
    labels         = item["labels"]
  }
  }
}

### GCS RESOURCES ####

resource "google_storage_bucket" "gcs_flags_bucket" {
  project  = var.application_project
  name     = "${var.application_project}-${var.gcs_flags_bucket_name}"
  # This bucket is used by the services so let's create in the same compute region
  location = var.compute_region

  force_destroy = !var.terraform_data_deletion_protection

  lifecycle_rule {
    condition {
      # Clean up old flags to save storage and GCS operations overhead
      age = 3 # days
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true

  depends_on = [google_project_service.enable_apis]
}

### LOGGING ####

resource "google_logging_project_sink" "bigquery-logging-sink" {
  name                   = var.log_sink_name
  destination            = "bigquery.googleapis.com/projects/${google_bigquery_dataset.logging_dataset.project}/datasets/${google_bigquery_dataset.logging_dataset.dataset_id}"
  filter                 = "jsonPayload.global_app=bq-pii-classifier"
  # Use a unique writer (creates a unique service account used for writing)
  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = true
  }

  depends_on = [google_project_service.enable_apis]
}
#### Resources

### bucket to store xxl configurations that can't fit in env variables in Cloud Run
resource "google_storage_bucket" "gcs_solution_resources" {
  project  = var.application_project
  name     = "${var.application_project}-resources"
  # This bucket is used by the services so let's create in the same compute region
  location = var.compute_region

  force_destroy = true

  uniform_bucket_level_access = true

  depends_on = [google_project_service.enable_apis]
}

### configs that are XXL to fit into a cloud run variable
resource "google_storage_bucket_object" "info_type_map_file" {
  name   = "INFO_TYPE_MAP.json"
  bucket = google_storage_bucket.gcs_solution_resources.name
  content_type = "application/json"
  content = jsonencode(local.info_types_map)
}





