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
variable "region" {
  type = string
}

variable "service_name" {
  type = string
}
variable "service_image" {
  type = string
}
variable "service_account_email" {
  type = string
}
variable "invoker_service_account_email" {
  type = string
}

variable "environment_variables" {
  type = list(object({
    name  = string,
    value = string
  }))
}

variable "max_memory" {
  type    = string
  default = "1Gi"
}

variable "max_cpu" {
  type    = string
  default = "1"
}

variable "max_containers" {
  type    = number
  default = 10
}

variable "max_requests_per_container" {
  type    = number
  default = 80
}

variable "timeout_seconds" {
  type = number
}

variable "container_entry_point_args" {
  type = list(string)
}
