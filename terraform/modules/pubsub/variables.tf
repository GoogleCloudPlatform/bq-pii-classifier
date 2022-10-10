variable "project" {
  type = string
}

variable "topic" {
  type = string
}
variable "subscription_name" {
  type = string
}
variable "subscription_endpoint" {
  type = string
}
variable "subscription_service_account" {
  type = string
}
variable "topic_publishers_sa_emails" {
  type = list(string)
}
variable "subscription_message_retention_duration" {
  type = string
}
variable "subscription_ack_deadline_seconds" {
  type = number
}
