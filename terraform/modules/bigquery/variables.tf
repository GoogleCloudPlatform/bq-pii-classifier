variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "dataset" {
  type = string

}

variable "standard_dlp_results_table_name" {
  type = string
}

variable "logging_sink_sa" {
  type = string
}


variable "created_policy_tags" {
  type = list(object({
    domain = string,
    classification = string,
    info_type = string,
    policy_tag_id = string
  }))
}

variable "projects_domains_mapping" {
  type = list(object({
    project = string,
    domain = string
  }))
}

variable "dataset_domains_mapping" {
  type = list(object({
    project = string,
    dataset = string,
    domain = string
  }))
}

variable "inspection_templates_count" {type = number}