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

variable "project" {
  type = string
}

variable "compute_region" {
  description = "GCP region to deploy compute resources (e.g. Cloud Run)"
  type = string
}

variable "data_region" {
  description = "GCP region to store application data (e.g. DLP results, logs, etc)"
  type = string
}

variable "source_data_regions" {
  description = "Supported GCP regions for DLP inspection and tagging. These are the regions to run DLP jobs in and deploy policy tags taxonomies."
  type = set(string)
}

variable "bigquery_dataset_name" {
  type = string
  default = "bq_pii_classifier"
}

variable "auto_dlp_results_table_name" {
  type = string
  description = "New table name to be created to hold DLP findings in the format 'table'"
  default = "auto_dlp_results"
}

variable "standard_dlp_results_table_name" {
  type = string
  default = "standard_dlp_results"
  description = "New table name to be created to hold DLP findings in the format 'table'"
}

variable "sa_tagging_dispatcher" {
  type = string
  default = "tag-dispatcher"
}

variable "sa_inspection_dispatcher" {
  type = string
  default = "insp-dispatcher"
}

variable "sa_tagging_dispatcher_tasks" {
  type = string
  default = "tag-dispatcher-tasks"
}

variable "sa_inspection_dispatcher_tasks" {
  type = string
  default = "insp-dispatcher-tasks"
}

variable "sa_inspector" {
  type = string
  default = "inspector"
}

variable "sa_inspector_tasks" {
  type = string
  default = "inspector-tasks"
}

variable "sa_tagger" {
  type = string
  default = "tagger"
}

variable "sa_tagger_tasks" {
  type = string
  default = "tagger-tasks"
}

variable "sa_bq_remote_func_get_policy_tags" {
  type = string
  default = "sa-func-get-policy-tags"
}

variable "tagger_role" {
  type = string
  default = "tagger_role"
}

variable "log_sink_name" {
  type = string
  default = "sc_bigquery_log_sink"
}

variable "tagging_scheduler_name" {
  type = string
  default = "tagging-scheduler"
}

variable "inspection_scheduler_name" {
  type = string
  default = "inspection-scheduler"
}

variable "tagging_dispatcher_service_name" {
  type = string
  default = "s1a-tagging-dispatcher"
}

variable "inspection_dispatcher_service_name" {
  type = string
  default = "s1b-inspection-dispatcher"
}

variable "inspector_service_name" {
  type = string
  default = "s2-inspector"
}

variable "tagger_service_name" {
  type = string
  default = "s3-tagger"
}

variable "bq_remote_func_get_policy_tags_name" {
  type = string
  default = "get_table_policy_tags"
}


variable "tagging_dispatcher_pubsub_topic" {
  type = string
  default = "tagging_dispatcher_topic"
}

variable "inspection_dispatcher_pubsub_topic" {
  type = string
  default = "inspection_dispatcher_topic"
}

variable "tagging_dispatcher_pubsub_sub" {
  type = string
  default = "tagging_dispatcher_push_sub"
}

variable "inspection_dispatcher_pubsub_sub" {
  type = string
  default = "inspection_dispatcher_push_sub"
}

variable "inspector_pubsub_topic" {
  type = string
  default = "inspector_topic"
}

variable "inspector_pubsub_sub" {
  type = string
  default = "inspector_push_sub"
}

variable "tagger_pubsub_topic" {
  type = string
  default = "tagger_topic"
}

variable "tagger_pubsub_sub" {
  type = string
  default = "tagger_push_sub"
}


# Images
variable "gar_docker_repo_name" {
  type = string
  default = "bq-pii-classifier"
}

variable "tagging_dispatcher_service_image" {
  type = string
}

variable "tagger_service_image" {
  type = string
}

variable "inspection_dispatcher_service_image" {
  type = string
  description = "Optional. Only needed when is_auto_dlp_mode = false"
  default = "(N/A)"
}

variable "inspector_service_image" {
  type = string
  description = "Optional. Only needed when is_auto_dlp_mode = false"
  default = "(N/A)"
}

# DLP scanning scope
# Optional fields. At least one should be provided among the _INCLUDE configs
# format: project.dataset.table1, project.dataset.table2, etc
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
# Custom types must be defined manually in th dlp inspection template
# INFO_TYPEs configured in the DLP inspection job MUST be mapped here. Otherwise, mapping to policy tag ids will fail
variable "classification_taxonomy" {
  type = list(object({
    info_type = string
    info_type_category = string
    # (standard | custom)
    policy_tag = string
    classification = string
    labels = optional(list(object({key = string, value = string})), [])
    inspection_template_number = optional(number, 1)
    taxonomy_number = optional(number, 1)
  }))
}
//Example:
//classification_taxonomy = [
//  {
//    info_type = "EMAIL_ADDRESS",
//    info_type_category = "standard",
//    policy_tag = "email",
//    classification = "P1",
//    labels   = [{ key = "contains_email_pii", value = "true"}],
//    inspection_template_number = 1,
//    taxonomy_number = 1
//  },
//  {
//    info_type = "PHONE_NUMBER",
//    info_type_category = "standard",
//    policy_tag = "phone"
//    classification = "P2",
//    labels   = [{ key = "contains_phones_pii", value = "true"}],
//    inspection_template_number = 1,
//    taxonomy_number = 1
//  },
//  {
//    info_type = "MIXED",
//    info_type_category = "other",
//    policy_tag = "mixed_pii"
//    classification = "P1",
//    labels = [],
//    inspection_template_number = 1,
//    taxonomy_number = 1
//  }
//  ]

variable "custom_info_types_dictionaries" {
  type = list(object({
    name = string
    likelihood = string
    dictionary =list(string)
  }))
}

variable "custom_info_types_regex" {
  type = list(object({
    name = string
    likelihood = string
    regex = string
  }))
}

variable "domain_mapping" {
  type = list(object({
    project = string,
    domain = string,
    datasets = list(object({
      name = string,
      domain = string
    })) // leave empty if no dataset overrides is required for this project
  }))
  description = "Mapping between domains and GCP projects or BQ Datasets. Dataset-level mapping will overwrite project-level mapping for a given project."
}
// Example:
//domain_mapping = [
//  {
//    project = "marketing-project",
//    domain = "marketing",
//    datasets = []
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
  type = map(map(list(string)))
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

variable "terraform_service_account" {
  type = string
  description = "service account used by terraform to deploy to GCP"
}

variable "is_dry_run_tags" {
  type = string
  default = "False"
  description = "Applying Policy Tags in the Tagger function (False) or just logging actions (True)"
}

variable "is_dry_run_labels" {
  type = string
  default = "False"
  description = "Applying resource labels in the Tagger function (False) or just logging actions (True)"
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

  type = object({
    limitType = string, // NUMBER_OF_ROWS or PERCENTAGE_OF_ROWS
    limits = map(string)
  })
  description = "JSON config to specify table scan limits intervals"

  default = {
    limitType: "NUMBER_OF_ROWS",
    limits: {
      "10000":"100",
      "100000":"1000",
      "1000000":"10000"
    }
  }
}

variable "is_auto_dlp_mode" {
  type = bool
  default = false
}

// In case of False:
//  The solution will report the infotype of a field as "MIXED" if DLP finds more than one InfoType for that field (regardless of likelyhood and number of findings)
// In case of True:
//  The solution will compute a score for each field that DLP finds multiple infotypes for (based on signals like likelyhood and number of findings)
//  , if the scores are still a tie, the solution will fallback to "MIXED" infoType
variable "promote_mixed_info_types" {
  type = bool
  default = false
  description = "Optional. Only needed when is_auto_dlp_mode = false"
}

// The threshold for DLP to report an INFO_TYPE as finding
variable "dlp_min_likelihood" {
  type = string
  default = "LIKELY"
  description = "Optional. Only needed when is_auto_dlp_mode = false"
}

// Number of findings (i.e. records) that DLP will report.
// This setting directly affected the number of DLP findings that we consider to apply tagging.
// DLP will inspect the full data sample anyways, regardless of the max findings config.
// Thus, this setting shouldn't affect DLP cost.
// However, It affects BigQuery storage cost for storing more findings and the DLP job execution time
// Set to 0 for DLP max
variable "dlp_max_findings_per_item" {
  type = number
  default = 0
  description = "Optional. Only needed when is_auto_dlp_mode = false"
}


//How to sample rows if not all rows are scanned.
//Meaningful only when used in conjunction with either rows_limit or rows_limit_percent.
//If not specified, rows are scanned in the order BigQuery reads them.
//RANDOM_START = 2
//SAMPLE_METHOD_UNSPECIFIED = 0
//TOP = 1
variable "dlp_sampling_method" {
  type = number
  default = 2
  description = "Optional. Only needed when is_auto_dlp_mode = false"
}

// Use ["FINE_GRAINED_ACCESS_CONTROL"] to restrict IAM access on tagged columns.
// Use [] NOT to restrict IAM access.
variable "data_catalog_taxonomy_activated_policy_types" {
  type = list(string)
  default = ["FINE_GRAINED_ACCESS_CONTROL"]
  description = "A lis of policy types for the created taxonomy(s)"
}

variable "gcs_flags_bucket_name" {
  type = string
  default = "bq-pii-classifier-flags"
}

# Dispatcher settings.
variable "dispatcher_service_timeout_seconds" {
  description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
  type = number
  # Dispatcher might need relatively long time to process large BigQuery scan scopes
  default = 540
  # 9m
}

variable "dispatcher_subscription_ack_deadline_seconds" {
  description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
  type = number
  // This should be higher than the service_timeout_seconds to avoid retrying messages that are still processing
  // range is 10 to 600
  default = 600
  # 10m
}

variable "dispatcher_subscription_message_retention_duration" {
  description = "How long to retain unacknowledged messages in the subscription's backlog"
  type = string
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions (e.g. Tagger issuing unnecessary BQ queries)
  # min value must be at least equal to the ack_deadline_seconds
  # Dispatcher should have the shortest retention possible because we want to avoid retries (on the app level as well)
  default = "600s"
  # 10m
}

# Inspector settings.
variable "inspector_service_timeout_seconds" {
  description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
  type = number
  default = 300
  # 5m
}

variable "inspector_subscription_ack_deadline_seconds" {
  description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
  type = number
  // This should be higher than the service_timeout_seconds to avoid retrying messages that are still processing
  default = 420
  # 7m
}

variable "inspector_subscription_message_retention_duration" {
  description = "How long to retain unacknowledged messages in the subscription's backlog"
  type = string
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions (e.g. Tagger issuing unnecessary BQ queries)
  # It also sets how long should we keep trying to process one run
  # min value must be at least equal to the ack_deadline_seconds
  # Inspector should have a relatively long retention to handle runs with large number of tables.
  default = "86400s"
  # 24h
}

# Tagger settings.
variable "tagger_service_timeout_seconds" {
  description = "Max period for the cloud run service to complete a request. Otherwise, it terminates with HTTP 504 and NAK to PubSub (retry)"
  type = number
  # Tagger is using BQ batch jobs that might need time to start running and thus a relatively longer timeout
  default = 540
  # 9m
}

variable "tagger_subscription_ack_deadline_seconds" {
  description = "This value is the maximum time after a subscriber receives a message before the subscriber should acknowledge the message. If it timeouts without ACK PubSub will retry the message."
  type = number
  // This should be higher than the service_timeout_seconds to avoid retrying messages that are still processing
  // range is 10 to 600
  default = 600
  # 10m
}

variable "tagger_subscription_message_retention_duration" {
  description = "How long to retain unacknowledged messages in the subscription's backlog"
  type = string
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions (e.g. Tagger issuing unnecessary BQ queries)
  # It also sets how long should we keep trying to process one run
  # min value must be at least equal to the ack_deadline_seconds
  # Inspector should have a relatively long retention to handle runs with large number of tables.
  default = "86400s"
  # 24h
}

variable "taxonomy_name_suffix" {
  type = string
  default = ""
  description = "Suffix added to taxonomy display name to make it unique within an org"
}

variable "terraform_data_deletion_protection" {
  type = bool
  # Allow destroying BQ datasets and GCS buckets. Set to true for production use
  default = false
}




