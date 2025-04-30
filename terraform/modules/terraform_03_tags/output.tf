output "dlp_tag_high_sensitivity_id" {
  value =  google_tags_tag_value.dlp_high_sensitivity_value.namespaced_name
}

output "dlp_tag_moderate_sensitivity_id" {
  value =  google_tags_tag_value.dlp_moderate_sensitivity_value.namespaced_name
}

output "dlp_tag_low_sensitivity_id" {
  value =  google_tags_tag_value.dlp_low_sensitivity_value.namespaced_name
}
