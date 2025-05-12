#############################################################
#                                    DLP Sensitivity Tags
##############################################################

resource "google_tags_tag_key" "dlp_sensitivity_level_key" {
  parent      = "organizations/${var.org_id}"
  short_name  = var.dlp_tag_sensitivity_level_key_name
  description = "Cloud DLP data sensitivity level."
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

#############################################################
#                                    DLP Ignore Tags
##############################################################

resource "google_tags_tag_key" "ignore_dlp_key" {
  parent      = "organizations/${var.org_id}"
  short_name  = var.ignore_dlp_sensitivity_key_name
  description = "A signal to ignore Cloud DLP automated sensitivity tag."
}

resource "google_tags_tag_value" "ignore_dlp_true_value" {
  parent      = google_tags_tag_key.ignore_dlp_key.id
  short_name  = var.ignore_dlp_sensitivity_true_value_name
  description = "Ignore Cloud DLP automated sensitivity tag."
}

#############################################################
#                                    Tags IAM
##############################################################

# principles need to be tag users on the tag and the resource to create a binding

resource "google_tags_tag_key_iam_member" "dlp_sensitivity_level_key_iam_tag_user" {
  count = length(var.dlp_tag_sensitivity_level_key_iam_tag_user_principles)
  member  = var.dlp_tag_sensitivity_level_key_iam_tag_user_principles[count.index]
  role    = "roles/resourcemanager.tagUser"
  tag_key = google_tags_tag_key.dlp_sensitivity_level_key.id
}

resource "google_tags_tag_key_iam_member" "ignore_dlp_key_iam_tag_user" {
  count = length(var.ignore_dlp_sensitivity_key_iam_tag_user_principles)
  member  = var.ignore_dlp_sensitivity_key_iam_tag_user_principles[count.index]
  role    = "roles/resourcemanager.tagUser"
  tag_key = google_tags_tag_key.ignore_dlp_key.id
}