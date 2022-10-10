variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "gcs_flags_bucket_name" {
  type = string
}

variable "gcs_flags_bucket_admins" {
  type = list(string)
}