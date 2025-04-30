variable "org_id" {
  type = number
  description = "GCP organization ID that will host the DLP discovery service configuration"
}

variable "dlp_tag_sensitivity_level_key_name" {
  type = string
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