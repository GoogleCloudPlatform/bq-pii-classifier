variable "org_id" {
  type = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
}

variable "dlp_tag_sensitivity_level_key_name" {
  type = string
}

variable "ignore_dlp_sensitivity_key_name" {
  type = string
}

variable "dlp_tag_sensitivity_level_key_iam_tag_user_principles" {
  type = list(string)
  description = "List of principles to have roles/resourcemanager.tagUser on the 'DLP sensitivity' tags"
}

variable "ignore_dlp_sensitivity_key_iam_tag_user_principles" {
  type = list(string)
  description = "List of principles to have roles/resourcemanager.tagUser on the 'Ignore DLP Sensitivity' tags"
}

variable "dlp_tag_high_sensitivity_value_name" {
  type = string
  default = "high"
}

variable "dlp_tag_moderate_sensitivity_value_name" {
  type = string
  default = "moderate"
}

variable "dlp_tag_low_sensitivity_value_name" {
  type = string
  default = "low"
}

variable "ignore_dlp_sensitivity_true_value_name" {
  type = string
  default = "true"
}