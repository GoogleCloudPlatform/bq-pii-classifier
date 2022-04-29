variable "project" {}
variable "region" {}

variable "service_name" {}
variable "service_image" {}
variable "service_account_email" {}
variable "invoker_service_account_email" {}

variable "environment_variables" {}

variable "max_memory" {
  default = "1Gi"
}

variable "max_cpu" {
  default = "1"
}

variable "max_containers" {
  default = 10
}

variable "max_requests_per_container" {
  default = 80
}

variable "timeout_seconds" {}
