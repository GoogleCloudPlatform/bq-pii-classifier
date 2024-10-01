variable "project" {
  type = string
}
variable "region" {
  type = string
}

variable "domain" {
  type = string
  description = "the domain name for the taxonomy"
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
  description = "A lis of Maps defining children nodes"
}

// Use ["FINE_GRAINED_ACCESS_CONTROL"] to restrict IAM access on tagged columns.
// Use [] NOT to restrict IAM access.
variable "data_catalog_taxonomy_activated_policy_types" {
  type = list(string)
  description = "A lis of policy types for the created taxonomy(s)"
}

variable "taxonomy_number" {type = number}
