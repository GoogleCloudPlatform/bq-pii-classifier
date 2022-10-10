variable "project" {
  type = string
}
variable "region" {
  type = string
}
variable "sa_tagging_dispatcher" {
  type = string
}
variable "sa_tagger" {
  type = string
}
variable "sa_tagging_dispatcher_tasks" {
  type = string
}
variable "sa_tagger_tasks" {
  type = string
}
variable "taxonomy_parent_tags" {
  type = list(object({
    id = string,
    domain = string,
    display_name = string
  }))
}
variable "iam_mapping" {
  type = map(map(list(string)))
}
variable "dlp_service_account" {
  type = string
}
variable "tagger_role" {
  type = string
}
variable "bq_results_dataset" {
  type = string
}