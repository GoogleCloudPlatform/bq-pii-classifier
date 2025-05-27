# Wave 1:
# Create a bucket
# Attach external tag to the bucket manually
# Attach external label

# Wave 2:
# Create a tag in TF
# Assign the tag to the bucket
# Assign a new label to the bucket
# Observe if TF deletes existing tags or labels

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "org_id" {
  type = number
}

variable "terraform_service_account_email" {
  type = string
  description = "Serviced account to be used by Terraform to deploy resources"
}

resource "google_storage_bucket" "bucket" {
  project  = var.project
  name     = "${var.project}-tags-and-tf-sandbox"
  # This bucket is used by the services so let's create in the same compute region
  location = var.region

  labels = {applied_by_tf="yes"}

  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_tags_tag_key" "key" {
  parent      = "organizations/${var.org_id}"
  short_name  = "tf_tags_test"
  description = "Testing tags and TF behaviour."
}

resource "google_tags_tag_value" "value" {
  parent      = google_tags_tag_key.key.id
  short_name  = "applied-by-tf"
  description = "Testing tags and TF behaviour."
}

resource "google_tags_tag_key_iam_member" "tag_user" {
  member  = "serviceAccount:${var.terraform_service_account_email}"
  role    = "roles/resourcemanager.tagUser"
  tag_key = google_tags_tag_key.key.id
}

resource "google_tags_location_tag_binding" "tag_binding" {
  parent    = "//storage.googleapis.com/projects/_/buckets/${google_storage_bucket.bucket.name}"
  location = google_storage_bucket.bucket.location
  tag_value = google_tags_tag_value.value.id
  depends_on = [google_tags_tag_key_iam_member.tag_user]
}