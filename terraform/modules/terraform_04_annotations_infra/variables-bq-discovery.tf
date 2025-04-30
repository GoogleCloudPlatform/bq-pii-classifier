
variable "auto_dlp_results_table_name" {
  type = string
  description = "New table name to be created to hold DLP findings in the format 'table'"
  default = "dlp_discovery_services_bq_results"
}


variable "tagger_bq_service_account_name" {
  type = string
}

variable "workflows_bq_name" {
  type = string
  default = "bigquery_tables_re_annotation_trigger"
}

variable "workflows_bq_description" {
  type = string
  default = "Trigger (re)annotation process for BigQuery tables based on DLP findings"
}

variable "tagger_service_name" {
  type = string
  default = "tagger-bq"
}

variable "tagger_pubsub_topic" {
  type = string
  default = "tagger_bq_topic"
}

variable "tagger_pubsub_sub" {
  type = string
  default = "tagger_bq_push_sub"
}

variable "domain_mapping" {
  type = list(object({
    project = string,
    domain = string,
    datasets = list(object({
      name = string,
      domain = string
    })) // leave empty if no dataset overrides is required for this project
  }))
  default = []
  description = "Mapping between domains and GCP projects or BQ Datasets. Dataset-level mapping will overwrite project-level mapping for a given project."
}

variable "iam_mapping" {
  type = map(map(list(string)))
  default = {}
  description = "Dictionary of mappings between domains/classification and IAM members to grant required permissions to read sensitive BQ columns belonging to that domain/classification"
}

// Use ["FINE_GRAINED_ACCESS_CONTROL"] to restrict IAM access on tagged columns.
// Use [] NOT to restrict IAM access.
variable "data_catalog_taxonomy_activated_policy_types" {
  type = list(string)
  default = []
  description = "A lis of policy types for the created taxonomy(s)"
}

variable "taxonomy_name_suffix" {
  type = string
  default = ""
  description = "Suffix added to taxonomy display name to make it unique within an org"
}

variable "is_dry_run_tags" {
  type = bool
  default = false
  description = "Applying Policy Tags in the Tagger function (False) or just logging actions (True)"
}

variable "default_domain_name" {
  type = string
  default = "default_domain"
  description = "default domain to use when domain_mapping is empty. This is used in deployments where only one domain is required and/or as a fallback for projects and datasets without explicit domain mapping."
}

variable "bq_existing_labels_regex" {
  type = string
  default = "(?!)" // Negative lookahead with an empty pattern to never match labels
  description = "A regex used to match existing bucket labels to be deleted and re-created based on the newest DLP findings and info type mapping"
}

variable "promote_dlp_other_matches" {
  type = bool
  default = false
  description = "When set to true, the tagger service will include the 'other_matches' that DLP finds for a particular table to promote one policy tag per column"
}



# Tagger Scalability params

# Discovery Tagging:
#   BQ Tagger hits the DLP API (get data profile), and BQ API (update table)
#   DLP API: 600 requests per minute
#   BQ API: NA
# Dispatcher Tagging:
#   Only hits the BQ API to add labels to buckets

variable "tagger_bq_service_max_containers" {
  type = number
  default = 1
}

variable "tagger_bq_service_max_requests_per_container" {
  type = number
  default = 80
}

variable "tagger_bq_service_max_cpu" {
  type = number
  default = 2
}

variable "tagger_bq_service_max_memory" {
  type = string
  default = "4Gi"
}

variable "dlp_for_bq_pubsub_topic_name" {
  type = string
  default = "dlp_results_for_bq_topic"
}