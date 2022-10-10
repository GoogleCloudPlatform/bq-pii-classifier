variable "project" {
  type = string
}
variable "region" {
  type = string
}
variable "classification_taxonomy" {
  type = list(object({
    info_type = string
    info_type_category = string
    # (standard | custom)
    policy_tag = string
    classification = string
  }))
}