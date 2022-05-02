# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "gcs_flags_bucket" {
  name          = var.gcs_flags_bucket_name
  # This bucket is used by the services so let's create in the same compute region
  location      = var.region

  # force_destroy = true

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
}

resource "google_storage_bucket_iam_binding" "gcs_flags_bucket_iam_bindings" {
  bucket = google_storage_bucket.gcs_flags_bucket.name
  role = "roles/storage.objectAdmin"
  members = var.gcs_flags_bucket_admins
}
