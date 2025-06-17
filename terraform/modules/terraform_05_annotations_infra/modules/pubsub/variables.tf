#
#
#  Copyright 2025 Google LLC
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       https://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#  implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#

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
variable "retain_acked_messages" {
  type    = bool
  default = false
}
