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

locals {

  service_image_uri = "${var.compute_region}-docker.pkg.dev/${var.project}/${var.gar_docker_repo_name}/${var.image_name}"

  project_and_domains = distinct([
    for entry in var.domain_mapping : {
      project = entry["project"],
      domain  = entry["domain"]
    }
  ])

  # Only projects with configured domains
  project_and_domains_filtered = [for entry in local.project_and_domains : entry if entry["domain"] != ""]

  datasets_and_domains = distinct(flatten([
    for entry in var.domain_mapping : [
      for dataset in lookup(entry, "datasets", []) : {
        project = entry["project"],
        dataset = dataset["name"],
        domain  = dataset["domain"]
      }
    ]
  ]))

  # Only datasets with configured domains
  datasets_and_domains_filtered = [for entry in local.datasets_and_domains : entry if entry["domain"] != ""]

  # Get distinct domains set on project entries
  project_domains = distinct([
    for entry in local.project_and_domains_filtered : entry["domain"]
  ])

  # Get distinct domains set on dataset level
  dataset_domains = distinct([
    for entry in local.datasets_and_domains_filtered : entry["domain"]
  ])

  // Concat project and dataset domains and filter out empty strings
  domains = distinct(concat(local.project_domains, local.dataset_domains, [var.default_domain_name]))

  # comma separated string with taxonomy names
  created_taxonomies = join(",", [for taxonomy in module.data-catalog[*].created_taxonomy : taxonomy.name])

  // one list of all policy tags generated across domain taxonomies
  // each element of the list is a map with three attributes (policy_tag_id, domain, classification, info_type, region)
  created_policy_tags = flatten(module.data-catalog[*].created_children_tags)

  created_parent_tags = flatten(module.data-catalog[*].created_parent_tags)

  auto_dlp_results_latest_view = "${var.auto_dlp_results_table_name}_latest_v1"

  taxonomy_numbers = distinct([for x in var.classification_taxonomy : x["taxonomy_number"]])

  // this return a list of lists of [[gcp_region, domain, taxonomy_number]] like [ ["europe-west3","dwh","1"], ["europe-west3","dwh","2"], ["europe-west3","marketing","1"], ["europe-west3","marketing","2"], etc ]
  taxonomies_to_be_created = setproduct(tolist(var.source_data_regions), local.domains, local.taxonomy_numbers)

  sa_tagger_email = "${var.tagger_bq_service_account_name}@${var.project}.iam.gserviceaccount.com"

  sa_application_email = "${var.application_service_account_name}@${var.project}.iam.gserviceaccount.com"
}

data google_project "gcp_project" {
  project_id = var.project
}

### configs that are XXL to fit into a cloud run variable
resource "google_storage_bucket_object" "info_type_policy_tag_map_file" {
  name         = "INFO_TYPE_POLICY_TAG_MAP.json"
  bucket       = var.resources_bucket_name
  content_type = "application/json"
  content      = jsonencode(local.created_policy_tags)
}

module "cloud-run-tagger" {
  source                        = "../../modules/cloud_run"
  project                       = var.project
  region                        = var.compute_region
  service_image                 = local.service_image_uri
  container_entry_point_args    = ["-cp", "@/app/jib-classpath-file", var.java_class_path_bq_tagger_service]
  service_name                  = var.tagger_service_name
  service_account_email         = local.sa_tagger_email
  invoker_service_account_email = local.sa_application_email
  max_containers                = var.tagger_service_max_containers
  max_requests_per_container    = var.tagger_service_max_requests_per_container
  max_cpu                       = var.tagger_service_max_cpu
  max_memory                    = var.tagger_service_max_memory
  timeout_seconds               = var.tagger_service_timeout_seconds
  environment_variables = [
    {
      name  = "IS_DRY_RUN_TAGS",
      value = var.is_dry_run_tags,
    },
    {
      name  = "IS_DRY_RUN_LABELS",
      value = var.is_dry_run_labels,
    },
    {
      name  = "TAXONOMIES",
      value = local.created_taxonomies,
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
      name  = "DEFAULT_DOMAIN_NAME",
      value = var.default_domain_name,
    },
    {
      name  = "EXISTING_LABELS_REGEX",
      value = var.bq_existing_labels_regex
    },
    {
      name  = "INFO_TYPE_POLICY_TAG_MAP",
      value = "gs://${var.resources_bucket_name}/${google_storage_bucket_object.info_type_policy_tag_map_file.name}"
    },
    {
      name  = "PROJECT_DOMAIN_MAP",
      value = jsonencode(local.project_and_domains_filtered)
    },
    {
      name  = "DATASET_DOMAIN_MAP",
      value = jsonencode(local.datasets_and_domains_filtered)
    },
    {
      name  = "PROMOTE_DLP_OTHER_MATCHES"
      value = var.promote_dlp_other_matches
    }
  ]
}

# connect the dlp notifications topic to the tagger service via a push subscription
resource "google_pubsub_subscription" "tagger-for-dlp-subscription" {
  project = var.project
  name    = "${var.tagger_pubsub_sub}_for_dlp"
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
    push_endpoint = "${module.cloud-run-tagger.service_endpoint}/dlp-discovery-service-handler"

    oidc_token {
      service_account_email = local.sa_application_email
    }
  }
}

module "pubsub-tagger-for-dispatcher" {
  source                       = "../../modules/pubsub"
  project                      = var.project
  subscription_endpoint        = "${module.cloud-run-tagger.service_endpoint}/tagging-dispatcher-handler"
  subscription_name            = "${var.tagger_pubsub_sub}_for_dispatcher"
  subscription_service_account = local.sa_application_email
  topic                        = "${var.tagger_pubsub_topic}_for_dispatcher"
  topic_publishers_sa_emails   = [local.sa_application_email]
  # 10m is max allowed
  subscription_ack_deadline_seconds = var.tagger_subscription_ack_deadline_seconds
  # How long to retain unacknowledged messages in the subscription's backlog, from the moment a message is published.
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions
  subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
}

### Data Catalog Policy Tags ####
module "data-catalog" {
  count   = length(local.taxonomies_to_be_created)
  source  = "../../modules/data_catalog"
  project = var.project
  region  = local.taxonomies_to_be_created[count.index][0]

  domain          = local.taxonomies_to_be_created[count.index][1]
  taxonomy_number = local.taxonomies_to_be_created[count.index][2]

  // only use the nodes that are marked for taxonomy number x
  classification_taxonomy = [for x in var.classification_taxonomy : x if x["taxonomy_number"] == local.taxonomies_to_be_created[count.index][2]]

  data_catalog_taxonomy_activated_policy_types = var.data_catalog_taxonomy_activated_policy_types
  taxonomy_name_suffix                         = var.taxonomy_name_suffix
}


## Data Catalog Taxonomies Permissions ##

locals {

  # For each parent tag: omit the tag_id and lookup the list of IAM members to grant access to
  parent_tags_with_members_list = [for parent_tag in local.created_parent_tags :
    {
      policy_tag_name = parent_tag["id"]
      # lookup the iam_mapping variable with the key <domain> and then sub-key <classification>
      # parent_tag.display_name is the classification

      # if no iam_mapping is provided, then assign an empty list of IAM members for that tag,
      # if not, get the configured IAM members for the classification level of that tag
      iam_members = length(var.iam_mapping) == 0 ? [] : lookup(
        // the domain-specific IAM mapping entry
        var.iam_mapping[parent_tag["domain"]],
        // The parent tag classification used as the display name
        parent_tag["display_name"],
        // if no IAM list is found for that domain-classification, use an empty list for iam members
        []
      )

  }]

  // flatten the iam_members list inside of parent_tags_with_members_list
  iam_members_list = flatten([for entry in local.parent_tags_with_members_list : [
    for member in lookup(entry, "iam_members", "NA") :
    {
      policy_tag_name = lookup(entry, "policy_tag_name", "NA")
      iam_member      = member
    }
  ]])
}

# Grant permissions for every member in the iam_members_list
resource "google_data_catalog_policy_tag_iam_member" "policy_tag_reader" {
  provider   = google
  count      = length(local.iam_members_list)
  policy_tag = local.iam_members_list[count.index]["policy_tag_name"]
  role       = "roles/datacatalog.categoryFineGrainedReader"
  member     = local.iam_members_list[count.index]["iam_member"]
}


resource "google_workflows_workflow" "bq_tagging_dispatcher_workflow" {

  project     = var.project
  name        = var.workflows_bq_name
  description = var.workflows_bq_description
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
          - datasetsRegex: $${default(map.get(input, "datasetsRegex"), ".*")}
          - tablesRegex: $${default(map.get(input, "tablesRegex"), ".*")}
    - create_batch_job:
        call: googleapis.batch.v1.projects.locations.jobs.create
        args:
          parent: $${"projects/" + project_id + "/locations/" + location}
          jobId: $${"bq-dispatcher-" + uuid.generate()}
          body:
            taskGroups:
                - taskSpec:
                    runnables:
                      - container:
                          imageUri: ${local.service_image_uri}
                          commands:
                            - "-cp"
                            - "@/app/jib-classpath-file"
                            - ${var.java_class_path_bq_dispatcher_service}
                            - $${foldersRegex}
                            - $${projectsRegex}
                            - $${datasetsRegex}
                            - $${tablesRegex}
                          entrypoint: java
                    computeResource:
                      memoryMib: ${var.dispatcher_cloud_batch_memory_mib}
                      cpuMilli: ${var.dispatcher_cloud_batch_cpu_millis}
                    maxRunDuration: ${var.dispatcher_cloud_batch_max_run_duration_seconds}s
                  taskEnvironments:
                    - variables:
                        PROJECT_ID: "${var.project}"
                        PUBLISHING_PROJECT_ID: "${var.publishing_project}"
                        TAGGER_TOPIC: "${module.pubsub-tagger-for-dispatcher.topic-name}"
                        LOGGING_DATASET: "${var.logging_dataset_name}"
                        DLP_RESULTS_DATASET: "${var.dlp_dataset_name}"
                        DLP_RESULTS_TABLE: "${local.auto_dlp_results_latest_view}"
                        DISPATCHER_RUNS_TABLE: "${google_bigquery_table.dispatcher_runs_bq_table.table_id}"

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
