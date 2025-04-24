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
    inspection_template_number = number
    taxonomy_number = number
  }))
}

variable "custom_info_types_dictionaries" {
  type = list(object({
    name = string
    likelihood = string
    dictionary =list(string)
  }))
}

variable "custom_info_types_regex" {
  type = list(object({
    name = string
    likelihood = string
    regex = string
  }))
}