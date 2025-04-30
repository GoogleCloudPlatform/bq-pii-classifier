variable "project" {
  type = string
}
variable "region" {
  type = string
}

variable "built_in_info_types" {
  type = list(object({
    info_type = string
    inspection_template_number = optional(number, 1)
  }))
}

variable "custom_info_types_dictionaries" {
  type = list(object({
    name = string
    likelihood = string
    dictionary =list(string)
    inspection_template_number = optional(number, 1)
  }))
}

variable "custom_info_types_regex" {
  type = list(object({
    name = string
    likelihood = string
    regex = string
    inspection_template_number = optional(number, 1)
  }))
}