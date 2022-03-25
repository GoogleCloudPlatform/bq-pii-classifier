variable "project" {}
variable "region" {}

variable "domain" {
  type = string
  description = "the domain name for the taxonomy"
}

#  example:
//[
//{
//policy_tag = "email",
//info_type = "EMAIL_ADDRESS"
//parent = "P2"
//},
//{
//policy_tag = "address",
//info_type = "STREET_ADDRESS"
//parent = "P1"
//}
//]
variable "nodes" {
  type = list
  description = "A lis of Maps defining children nodes"
}

// Use ["FINE_GRAINED_ACCESS_CONTROL"] to restrict IAM access on tagged columns.
// Use [] NOT to restrict IAM access.
variable "data_catalog_taxonomy_activated_policy_types" {
  type = list
  description = "A lis of policy types for the created taxonomy(s)"
}
