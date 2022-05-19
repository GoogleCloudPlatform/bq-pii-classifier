variable "project" {}

variable "topic" {}
variable "subscription_name" {}
variable "subscription_endpoint" {}
variable "subscription_service_account" {}
variable "topic_publishers_sa_emails" {
  type = list(string)
}
variable "subscription_message_retention_duration" {}
variable "subscription_ack_deadline_seconds" {}
