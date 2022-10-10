variable "project" {
  type = string
}
variable "region" {
  type = string
}
variable "scheduler_name" {
  type = string
}
variable "target_uri" {
  type = string
}
variable "cron_expression" {
  type = string
}

# DLP scanning scope
variable "tables_include_list" {
  type = list(string)
}
variable "tables_exclude_list" {
  type = list(string)
}
variable "datasets_include_list" {
  type = list(string)
}
variable "datasets_exclude_list" {
  type = list(string)
}
variable "projects_include_list" {
  type = list(string)
}
