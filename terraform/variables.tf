#   Copyright 2021 Google LLC
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

variable "project" {}

variable "compute_region" {}

variable "data_region" {}

variable "env" {}

variable "bigquery_dataset_name" {
  default = "bq_security_classifier"
}

variable "auto_dlp_results_table_name" {
  description = "New table name to be created to hold DLP findings in the format 'table'"
  default = "auto_dlp_results"
}

variable "standard_dlp_results_table_name" {
  default = "standard_dlp_results"
  description = "New table name to be created to hold DLP findings in the format 'table'"
}

variable "sa_tagging_dispatcher" {
  default = "tag-dispatcher"
}

variable "sa_inspection_dispatcher" {
  default = "insp-dispatcher"
}

variable "sa_tagging_dispatcher_tasks" {
  default = "tag-dispatcher-tasks"
}

variable "sa_inspection_dispatcher_tasks" {
  default = "insp-dispatcher-tasks"
}

variable "sa_inspector" {
  default = "inspector"
}

variable "sa_inspector_tasks" {
  default = "inspector-tasks"
}

variable "sa_listener" {
  default = "listener"
}

variable "sa_listener_tasks" {
  default = "listener-tasks"
}

variable "sa_tagger" {
  default = "tagger"
}

variable "sa_tagger_tasks" {
  default = "tagger-tasks"
}

variable "tagger_role" {
  default = "tagger_role"
}

variable "log_sink_name" {
  default = "sc_bigquery_log_sink"
}

variable "tagging_scheduler_name" {
  default = "tagging-scheduler"
}

variable "inspection_scheduler_name" {
  default = "inspection-scheduler"
}

variable "tagging_dispatcher_service_name" {
  default = "s1a-tagging-dispatcher"
}

variable "inspection_dispatcher_service_name" {
  default = "s1b-inspection-dispatcher"
}

variable "inspector_service_name" {
  default = "s2-inspector"
}

variable "listener_service_name" {
  default = "s3-listener"
}

variable "tagger_service_name" {
  default = "s4-tagger"
}


variable "tagging_dispatcher_pubsub_topic" {
  default = "tagging_dispatcher_topic"
}

variable "inspection_dispatcher_pubsub_topic" {
  default = "inspection_dispatcher_topic"
}

variable "tagging_dispatcher_pubsub_sub" {
  default = "tagging_dispatcher_push_sub"
}

variable "inspection_dispatcher_pubsub_sub" {
  default = "inspection_dispatcher_push_sub"
}

variable "inspector_pubsub_topic" {
  default = "inspector_topic"
}

variable "inspector_pubsub_sub" {
  default = "inspector_push_sub"
}

variable "listener_pubsub_topic" {
  default = "listener_topic"
}

variable "listener_pubsub_sub" {
  default = "listener_push_sub"
}

variable "tagger_pubsub_topic" {
  default = "tagger_topic"
}

variable "tagger_pubsub_sub" {
  default = "tagger_push_sub"
}



# Images
variable "tagging_dispatcher_service_image" {}

variable "tagger_service_image" {}

variable "inspection_dispatcher_service_image" {
  description = "Optional. Only needed when is_auto_dlp_mode = false"
  default = "(N/A)"
}

variable "inspector_service_image" {
  description = "Optional. Only needed when is_auto_dlp_mode = false"
  default = "(N/A)"
}

variable "listener_service_image" {
  description = "Optional. Only needed when is_auto_dlp_mode = false"
  default = "(N/A)"
}


# DLP scanning scope
# Optional fields. At least one should be provided among the _INCLUDE configs
# format: project.dataset.table1, project.dataset.table2, etc
variable "tables_include_list" {
  type = list(string)
}
variable "datasets_include_list" {
  type = list(string)
}
variable "projects_include_list" {
  type = list(string)
}
variable "datasets_exclude_list" {
  type = list(string)
}
variable "tables_exclude_list" {
  type = list(string)
}

# for each domain in scope, these policy tags will be created in a domain-specific taxonomy
# and mapped in BQ configuration with the generated policy_tag_id. Each policy tag will be created
# under a parent node based on the 'classification' field
# info_type_category: "standard" or "custom". Standard types will be added to the DLP inspection template automatically.
# Custom types must be defined manuanly in th template
# INFO_TYPEs configured in the DLP inspection job MUST be mapped here. Otherwise, mapping to policy tag ids will fail
variable "classification_taxonomy" {
  type = list(object({
    info_type = string
    info_type_category = string # (standard | custom)
    policy_tag = string
    classification = string
  }))
}
//Example:
//classification_taxonomy = [
//  {
//    info_type = "EMAIL_ADDRESS",
//    info_type_category = "standard",
//    policy_tag = "email",
//    classification = "P1"
//  },
//  {
//    info_type = "PHONE_NUMBER",
//    info_type_category = "standard",
//    policy_tag = "phone"
//    classification = "P2"
//  },
//  {
//    info_type = "MIXED",
//    info_type_category = "other",
//    policy_tag = "mixed_pii"
//    classification = "P1"
//  }
//  ]

variable "domain_mapping" {
  description = "Mapping between domains and GCP projects or BQ Datasets. Dataset-level mapping will overwrite project-level mapping for a given project."
}
// Example:
//domain_mapping = [
//  {
//    project = "marketing-project",
//    domain = "marketing"
//  },
//  {
//    project = "dwh-project",
//    domain = "dwh",
//    datasets = [
//      {
//        name = "marketing_dataset",
//        domain = "marketing"
//      },
//      {
//        name = "finance_dataset",
//        domain = "finance"
//      }
//    ]
//  }
//]


variable "iam_mapping" {
  description = "Dictionary of mappings between domains/classification and IAM members to grant required permissions to read sensitive BQ columns belonging to that domain/classification"
}
//Example:
//iam_mapping = {
//
//  marketing = {
//    P1 = ["user:marketing-p1-reader@example.com"],
//    P2 = ["user:marketing-p2-reader@example.com"]
//  },
//
//  finance = {
//    P1 = ["user:finance-p1-reader@example.com"],
//    P2 = ["user:finance-p2-reader@example.com"]
//  },
//
//  dwh = {
//    P1 = ["user:dwh-p1-reader@example.com"],
//    P2 = ["user:dwh-p2-reader@example.com"]
//  }
//}

variable "dlp_service_account" {
  description = "service account email for DLP to grant permissions to via Terraform"
}

variable "cloud_scheduler_account" {
  description = "Service agent account for Cloud Scheduler. Format service-<project number>@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

variable "terraform_service_account" {
  description = "service account used by terraform to deploy to GCP"
}

variable "is_dry_run" {
  type = string
  default = "False"
  description = "Applying Policy Tags in the Tagger function (False) or just logging actions (True)"
}

variable "tagging_cron_expression" {
  type = string
  description = "Cron expression used by the Tagging Scheduler"
}

variable "inspection_cron_expression" {
  type = string
  description = "Cron expression used by the Inspection Scheduler. Used only when is_auto_dlp_mode = true"
  default = "(N/A)"
}

variable "table_scan_limits_json_config" {
  type = string
  description = "JSON config to specify table scan limits intervals"
  // Example
  // "{"limitType": "NUMBER_OF_ROWS", "limits": {"10000": "100","100000": "5000", "1000000": "7000"}}"
  // "{"limitType": "PERCENTAGE_OF_ROWS", "limits": {"10000": "10","100000": "5", "1000000": "1"}}"
  default = "{\"limitType\": \"NUMBER_OF_ROWS\", \"limits\": {\"10000\": \"100\"}}"
}

variable "is_auto_dlp_mode" {
  type = bool
  default = false
}

// In case of False:
//  The solution will report the infotype of a filed as "MIXED" if DLP finds more than one InfoType for that field (regardless of likelyhood and number of findings)
// In case of True:
//  The solution will compute a score for each field that DLP finds multiple infotypes for (based on signals like likelyhood and number of findings)
//  , if the scores are still a tie, the solution will fallback to "MIXED" infoType
variable "promote_mixed_info_types" {
  type = bool
  default = false
  description = "Optional. Only needed when is_auto_dlp_mode = false"
}






