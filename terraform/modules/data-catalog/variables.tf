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
