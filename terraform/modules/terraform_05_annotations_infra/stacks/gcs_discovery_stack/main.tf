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

########################################################################################################################
#                                             DATA & LOCALS
########################################################################################################################

locals {
  service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.image_name}"

  auto_dlp_results_latest_view = "${var.dlp_gcs_bq_results_table_name}_latest_v1"

  sa_tagger_email = "${var.tagger_gcs_service_account_name}@${var.project}.iam.gserviceaccount.com"

  sa_application_email = "${var.application_service_account_name}@${var.project}.iam.gserviceaccount.com"
}


########################################################################################################################
#                                             Cloud Run
########################################################################################################################

module "cloud-run-tagger-gcs" {
  source        = "../../modules/cloud_run"
  project       = var.project
  region        = var.compute_region
  service_image = local.service_image_uri
  container_entry_point_args = [
    "-cp", "@/app/jib-classpath-file", var.java_class_path_gcs_tagger_service
  ]
  service_name                  = var.tagger_gcs_service_name
  service_account_email         = local.sa_tagger_email
  invoker_service_account_email = local.sa_application_email
  # Dispatcher could take time to list large number of tables
  timeout_seconds            = var.tagger_service_timeout_seconds
  max_containers             = var.tagger_service_max_containers
  max_requests_per_container = var.tagger_service_max_requests_per_container
  max_cpu                    = var.tagger_service_max_cpu
  max_memory                 = var.tagger_service_max_memory
  environment_variables = [
    {
      name  = "IS_DRY_RUN_LABELS",
      value = var.is_dry_run_labels,
    },
    {
      name  = "COMPUTE_REGION_ID",
      value = var.compute_region,
    },
    {
      name  = "PROJECT_ID",
      value = var.project,
    },
    {
      name  = "INFO_TYPE_MAP",
      value = var.info_type_map_file_path,
    },
    {
      name  = "EXISTING_LABELS_REGEX",
      value = var.gcs_existing_labels_regex,
    }
  ]
}

########################################################################################################################
#                                            PubSub
########################################################################################################################

# connect the dlp notifications topic to the tagger service via a push subscription
resource "google_pubsub_subscription" "tagger-for-dlp-subscription" {
  project = var.project
  name    = "${var.tagger_gcs_pubsub_sub}_for_dlp"
  topic   = var.dlp_notifications_topic_name

  # Use a relatively high value to avoid re-sending the message when the deadline expires.
  # Especially with the dispatchers that could take few minutes to list all tables for large scopes
  ack_deadline_seconds = var.tagger_subscription_ack_deadline_seconds

  # How long to retain unacknowledged messages in the subscription's backlog, from the moment a message is published.
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions (e.g. Tagger issuing unnecessary BQ queries)
  # It also sets how long should we keep trying to process one run
  message_retention_duration = var.tagger_subscription_message_retention_duration

  # If retain_acked_messages is true, then message_retention_duration also configures the retention of acknowledged messages, and thus configures how far back in time a subscriptions.seek can be done.
  # Indicates whether to retain acknowledged messages. If true, then messages are not expunged from the subscription's backlog, even if they are acknowledged, until they fall out of the messageRetentionDuration window
  retain_acked_messages = var.retain_dlp_tagger_pubsub_messages

  enable_message_ordering = false

  # The message sent to a subscriber is guaranteed not to be resent before the message's acknowledgement deadline expires
  enable_exactly_once_delivery = false

  # Policy to delete the subscription when in-active
  expiration_policy {
    # Never Expires. Empty to avoid the 31 days expiration.
    ttl = ""
  }

  retry_policy {
    # The minimum delay between consecutive deliveries of a given message
    minimum_backoff = "60s" #
    # The maximum delay between consecutive deliveries of a given message
    maximum_backoff = "600s" # 10 mins
  }

  push_config {
    push_endpoint = "${module.cloud-run-tagger-gcs.service_endpoint}/dlp-discovery-service-handler"

    oidc_token {
      service_account_email = local.sa_application_email
    }
  }
}

module "pubsub-tagger-gcs-for-dispatcher" {
  source                       = "../../modules/pubsub"
  project                      = var.project
  subscription_endpoint        = "${module.cloud-run-tagger-gcs.service_endpoint}/tagging-dispatcher-handler"
  subscription_name            = "${var.tagger_gcs_pubsub_sub}_for_dispatcher"
  subscription_service_account = local.sa_application_email
  topic                        = "${var.tagger_gcs_pubsub_topic}_for_dispatcher"
  topic_publishers_sa_emails   = [local.sa_application_email]
  # use a deadline large enough to process BQ listing for large scopes
  subscription_ack_deadline_seconds = var.tagger_subscription_ack_deadline_seconds
  # avoid resending dispatcher messages if things went wrong and the msg was NAK (e.g. timeout expired, app error, etc)
  # min value must be at equal to the ack_deadline_seconds
  subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
}

########################################################################################################################
#                                            Workflows
########################################################################################################################

resource "google_workflows_workflow" "gcs_tagging_dispatcher_workflow" {

  project     = var.project
  name        = var.workflows_gcs_name
  description = var.workflows_gcs_description
  region      = var.compute_region

  service_account = local.sa_application_email

  deletion_protection = false

  source_contents = <<-EOF
main:
  params: [input]
  steps:
    - init:
        assign:
          - project_id: ${var.project}
          - location: ${var.compute_region}
          - foldersRegex: $${default(map.get(input, "foldersRegex"), ".*")}
          - projectsRegex: $${default(map.get(input, "projectsRegex"), ".*")}
          - bucketsRegex: $${default(map.get(input, "bucketsRegex"), ".*")}
          - rowsMultiplicationFactor: $${default(map.get(input, "rowsMultiplicationFactor"), "1")}
    - create_batch_job:
        call: googleapis.batch.v1.projects.locations.jobs.create
        args:
          parent: $${"projects/" + project_id + "/locations/" + location}
          jobId: $${"gcs-dispatcher-" + uuid.generate()}
          body:
            taskGroups:
                - taskSpec:
                    runnables:
                      - container:
                          imageUri: ${local.service_image_uri}
                          commands:
                            - "-cp"
                            - "@/app/jib-classpath-file"
                            - ${var.java_class_path_gcs_dispatcher_service}
                            - $${foldersRegex}
                            - $${projectsRegex}
                            - $${bucketsRegex}
                            - $${rowsMultiplicationFactor}
                          entrypoint: java
                    computeResource:
                      memoryMib: ${var.dispatcher_cloud_batch_memory_mib}
                      cpuMilli: ${var.dispatcher_cloud_batch_cpu_millis}
                    maxRunDuration: ${var.dispatcher_cloud_batch_max_run_duration_seconds}s
                  taskEnvironments:
                    - variables:
                        PROJECT_ID: "${var.project}"
                        PUBLISHING_PROJECT_ID: "${var.publishing_project}"
                        TAGGER_TOPIC: "${module.pubsub-tagger-gcs-for-dispatcher.topic-name}"
                        LOGGING_DATASET: "${var.logging_dataset_name}"
                        DLP_RESULTS_DATASET: "${var.dlp_dataset_name}"
                        DLP_RESULTS_TABLE: "${local.auto_dlp_results_latest_view}"
                        DISPATCHER_RUNS_TABLE: "${google_bigquery_table.dispatcher_runs_gcs_table.table_id}"

                        PUBSUB_FLOW_CONTROL_MAX_OUTSTANDING_REQUESTS_BYTES : "${var.dispatcher_pubsub_client_config.pubsub_flow_control_max_outstanding_request_bytes}"
                        PUBSUB_FLOW_CONTROL_MAX_OUTSTANDING_ELEMENT_COUNT : "${var.dispatcher_pubsub_client_config.pubsub_flow_control_max_outstanding_element_count}"
                        PUBSUB_BATCHING_ELEMENT_COUNT_THRESHOLD           : "${var.dispatcher_pubsub_client_config.pubsub_batching_element_count_threshold}"
                        PUBSUB_BATCHING_REQUEST_BYTE_THRESHOLD            : "${var.dispatcher_pubsub_client_config.pubsub_batching_request_byte_threshold}"
                        PUBSUB_BATCHING_DELAY_THRESHOLD_MILLIS            : "${var.dispatcher_pubsub_client_config.pubsub_batching_delay_threshold_millis}"
                        PUBSUB_RETRY_INITIAL_RETRY_DELAY_MILLIS            : "${var.dispatcher_pubsub_client_config.pubsub_retry_initial_retry_delay_millis}"
                        PUBSUB_RETRY_RETRY_DELAY_MULTIPLIER              : "${var.dispatcher_pubsub_client_config.pubsub_retry_retry_delay_multiplier}"
                        PUBSUB_RETRY_MAX_RETRY_DELAY_SECONDS              : "${var.dispatcher_pubsub_client_config.pubsub_retry_max_retry_delay_seconds}"
                        PUBSUB_RETRY_INITIAL_RPC_TIMEOUT_SECONDS          : "${var.dispatcher_pubsub_client_config.pubsub_retry_initial_rpc_timeout_seconds}"
                        PUBSUB_RETRY_RPC_TIMEOUT_MULTIPLIER                : "${var.dispatcher_pubsub_client_config.pubsub_retry_rpc_timeout_multiplier}"
                        PUBSUB_RETRY_MAX_RPC_TIMEOUT_SECONDS              : "${var.dispatcher_pubsub_client_config.pubsub_retry_max_rpc_timeout_seconds}"
                        PUBSUB_RETRY_TOTAL_TIMEOUT_SECONDS                : "${var.dispatcher_pubsub_client_config.pubsub_retry_total_timeout_seconds}"
                        PUBSUB_EXECUTOR_THREAD_COUNT_MULTIPLIER            : "${var.dispatcher_pubsub_client_config.pubsub_executor_thread_count_multiplier}"

            allocationPolicy:
              serviceAccount:
                email: ${local.sa_application_email}
                scopes:
                  - https://www.googleapis.com/auth/cloud-platform
            logsPolicy:
              destination: CLOUD_LOGGING
        result: create_job_result
    - return_result:
        return: $${create_job_result}
EOF
}