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
  source        = "../../modules/cloud-run"
  project       = var.project
  region        = var.compute_region
  service_image = local.service_image_uri
  container_entry_point_args = [
    "-cp", "@/app/jib-classpath-file", "com.google.cloud.pso.bq_pii_classifier.apps.gcs_tagger.GcsTaggerController"
  ]
  service_name               = var.tagger_gcs_service_name
  service_account_email      = local.sa_tagger_email
  invoker_service_account_email = local.sa_application_email
  # Dispatcher could take time to list large number of tables
  timeout_seconds            = var.tagger_service_timeout_seconds
  max_containers                = var.tagger_service_max_containers
  max_requests_per_container    = var.tagger_service_max_requests_per_container
  max_cpu                       = var.tagger_service_max_cpu
  max_memory                    = var.tagger_service_max_memory
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
      name  = "GCS_FLAGS_BUCKET",
      value = var.gcs_flags_bucket_name,
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


module "pubsub-tagger-gcs-for-dlp" {
  source                                  = "../../modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = module.cloud-run-tagger-gcs.service_endpoint
  subscription_name                       = "${var.tagger_gcs_pubsub_sub}_for_dlp"
  subscription_service_account            = local.sa_application_email
  topic                                   = "${var.tagger_gcs_pubsub_topic}_for_dlp"
  topic_publishers_sa_emails = [var.dlp_service_account_email]
  # use a deadline large enough to process BQ listing for large scopes
  subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  # avoid resending dispatcher messages if things went wrong and the msg was NAK (e.g. timeout expired, app error, etc)
  # min value must be at equal to the ack_deadline_seconds
  subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
  retain_acked_messages                   = var.retain_dlp_tagger_pubsub_messages
  # to enable replays for messages published by DLP

}

module "pubsub-tagger-gcs-for-dispatcher" {
  source                                  = "../../modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = module.cloud-run-tagger-gcs.service_endpoint
  subscription_name                       = "${var.tagger_gcs_pubsub_sub}_for_dispatcher"
  subscription_service_account            = local.sa_application_email
  topic                                   = "${var.tagger_gcs_pubsub_topic}_for_dispatcher"
  topic_publishers_sa_emails = [local.sa_application_email]
  # use a deadline large enough to process BQ listing for large scopes
  subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
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
                            - "com.google.cloud.pso.bq_pii_classifier.apps.dispatcher.GcsDispatcher"
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
                        DLP_RESULTS_DATASET: "${var.bq_results_dataset}"
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


########################################################################################################################
#                                            DLP Configs
########################################################################################################################

module "gcs_dlp_configs" {
  source = "../../modules/dlp-gcs-discovery-config"

  count = length(var.dlp_gcs_discovery_configurations)

  dlp_gcs_scan_org_id = var.dlp_gcs_scan_org_id

  dlp_gcs_scan_folder_id                          = var.dlp_gcs_discovery_configurations[count.index].folder_id
  dlp_gcs_bucket_name_regex                       = var.dlp_gcs_discovery_configurations[count.index].bucket_name_regex
  dlp_gcs_project_id_regex                        = var.dlp_gcs_discovery_configurations[count.index].project_id_regex
  dlp_gcs_apply_tags                              = var.dlp_gcs_discovery_configurations[count.index].apply_tags
  dlp_gcs_create_configuration_in_paused_state    = var.dlp_gcs_discovery_configurations[count.index].create_configuration_in_paused_state
  dlp_gcs_reprofile_frequency               = var.dlp_gcs_discovery_configurations[count.index].reprofile_frequency
  dlp_gcs_reprofile_on_inspection_template_update = var.dlp_gcs_discovery_configurations[count.index].reprofile_frequency_on_inspection_template_update
  dlp_gcs_included_bucket_attributes              = var.dlp_gcs_discovery_configurations[count.index].included_bucket_attributes
  dlp_gcs_included_object_attributes              = var.dlp_gcs_discovery_configurations[count.index].included_object_attributes

  bq_results_dataset                = var.bq_results_dataset
  data_region                       = var.data_region
  dlp_gcs_bq_results_table_name     = var.dlp_gcs_bq_results_table_name
  dlp_inspection_templates_ids_list = var.dlp_inspection_templates_ids_list
  dlp_tag_high_sensitivity_id       = var.dlp_tag_high_sensitivity_id
  dlp_tag_low_sensitivity_id        = var.dlp_tag_low_sensitivity_id
  dlp_tag_moderate_sensitivity_id   = var.dlp_tag_moderate_sensitivity_id
  project                           = var.project
  pubsub_tagger_topic_id            = module.pubsub-tagger-gcs-for-dlp.topic-id
  publishing_project                = var.publishing_project
}