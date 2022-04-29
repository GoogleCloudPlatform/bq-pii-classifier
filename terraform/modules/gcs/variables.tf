variable "project" {}

variable "region" {}

variable "gcs_flags_bucket_name" {}

variable "gcs_flags_bucket_admins" {
  type = list(string)
}