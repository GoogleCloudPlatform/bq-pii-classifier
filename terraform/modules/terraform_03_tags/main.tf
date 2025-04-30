#############################################################
#                                    Org-level Tags
##############################################################

resource "google_tags_tag_key" "dlp_sensitivity_level_key" {
  parent      = "organizations/${var.org_id}"
  short_name  = var.dlp_tag_sensitivity_level_key_name
  description = "Data sensitivity level."
}

resource "google_tags_tag_value" "dlp_high_sensitivity_value" {
  parent      = google_tags_tag_key.dlp_sensitivity_level_key.id
  short_name  = var.dlp_tag_high_sensitivity_value_name
  description = "DLP detected potential high sensitivity pii (SPII)"
}

resource "google_tags_tag_value" "dlp_moderate_sensitivity_value" {
  parent      = google_tags_tag_key.dlp_sensitivity_level_key.id
  short_name  = var.dlp_tag_moderate_sensitivity_value_name
  description = "DLP detected potential sensitive information that is not classified as high"
}

resource "google_tags_tag_value" "dlp_low_sensitivity_value" {
  parent      = google_tags_tag_key.dlp_sensitivity_level_key.id
  short_name  = var.dlp_tag_low_sensitivity_value_name
  description = "DLP didn't detect sensitive information"
}

