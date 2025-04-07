
locals {
  dlp_regional_end_point = var.data_region == "eu" ? "europe" : var.data_region

  dlp_service_account_email = "service-${data.google_project.gcp_project.number}@dlp-api.iam.gserviceaccount.com"

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

}

data google_project "gcp_project" {
  project_id = var.project
}


module "cloud-run-tagging-dispatcher" {
  source                        = "../../modules/cloud-run"
  project                       = var.project
  region                        = var.compute_region
  service_image                 = local.service_image_uri
  container_entry_point_args    = ["-cp", "@/app/jib-classpath-file", "com.google.cloud.pso.bq_pii_classifier.apps.bq_dispatcher.BigQueryDispatcherController"]
  service_name                  = var.tagging_dispatcher_service_name
  service_account_email         = google_service_account.sa_tagging_dispatcher.email
  invoker_service_account_email = google_service_account.sa_tagging_dispatcher_tasks.email
  # Dispatcher could take time to list large number of tables
  timeout_seconds               = var.dispatcher_service_timeout_seconds
  max_containers                = 1
  max_cpu                       = var.dispatcher_service_max_cpu
  max_memory = var.dispatcher_service_max_memory
  max_requests_per_container = 1 # process one tagging dispatcher request at a time
  environment_variables         = [
    {
      name  = "TAGGER_TOPIC",
      value = module.pubsub-tagger-for-dispatcher.topic-name,
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
      name  = "SOLUTION_DATASET",
      value = var.bigquery_dataset_name,
    },
    {
      name  = "DLP_TABLE_AUTO",
      value = local.auto_dlp_results_latest_view,
    },
    {
      name  = "DISPATCHER_RUNS_TABLE",
      value = google_bigquery_table.dispatcher_runs_bq_table.table_id,
    }
  ]

  depends_on = [google_project_iam_member.sa_dispatcher_roles_binding]
}

### configs that are XXL to fit into a cloud run variable
resource "google_storage_bucket_object" "info_type_policy_tag_map_file" {
  name   = "INFO_TYPE_POLICY_TAG_MAP.json"
  bucket = var.resources_bucket_name
  content_type = "application/json"
  content = jsonencode(local.created_policy_tags)
}

module "cloud-run-tagger" {
  source                        = "../../modules/cloud-run"
  project                       = var.project
  region                        = var.compute_region
  service_image                 = local.service_image_uri
  container_entry_point_args    = ["-cp", "@/app/jib-classpath-file", "com.google.cloud.pso.bq_pii_classifier.apps.bq_tagger.BigQueryTaggerController"]
  service_name                  = var.tagger_service_name
  service_account_email         = google_service_account.sa_tagger.email
  invoker_service_account_email = google_service_account.sa_tagger_tasks.email
  # no more than 80 requests at a time to handle BigQuery API rate limiting
  max_containers                = 1
  max_requests_per_container    = 80
  timeout_seconds               = var.tagger_service_timeout_seconds
  environment_variables         = [
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
      name  = "GCS_FLAGS_BUCKET",
      value = var.gcs_flags_bucket_name,
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
      name = "PROMOTE_DLP_OTHER_MATCHES"
      value = var.promote_dlp_other_matches
    }
  ]

  depends_on = [google_project_iam_member.sa_tagger_roles_binding]
}

module "pubsub-tagging-dispatcher" {
  source                                  = "../../modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = module.cloud-run-tagging-dispatcher.service_endpoint
  subscription_name                       = var.tagging_dispatcher_pubsub_sub
  subscription_service_account            = google_service_account.sa_tagging_dispatcher_tasks.email
  topic                                   = var.tagging_dispatcher_pubsub_topic
  topic_publishers_sa_emails              = [google_service_account.sa_workflows_bq.email]
  # use a deadline large enough to process BQ listing for large scopes
  subscription_ack_deadline_seconds       = var.dispatcher_subscription_ack_deadline_seconds
  # avoid resending dispatcher messages if things went wrong and the msg was NAK (e.g. timeout expired, app error, etc)
  # min value must be at equal to the ack_deadline_seconds
  subscription_message_retention_duration = var.dispatcher_subscription_message_retention_duration

}

module "pubsub-tagger-for-dlp" {
  source                                  = "../../modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = "${module.cloud-run-tagger.service_endpoint}/dlp-discovery-service-handler"
  subscription_name                       = "${var.tagger_pubsub_sub}_for_dlp"
  subscription_service_account            = google_service_account.sa_tagger_tasks.email
  topic                                   = "${var.tagger_pubsub_topic}_for_dlp"
  // DLP service account must be able to publish messages to the Tagger
  topic_publishers_sa_emails              = [local.dlp_service_account_email]
  # 10m is max allowed
  subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  # How long to retain unacknowledged messages in the subscription's backlog, from the moment a message is published.
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions
  subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
  retain_acked_messages                   = var.retain_dlp_tagger_pubsub_messages # to replay messages generated by dlp
}

module "pubsub-tagger-for-dispatcher" {
  source                                  = "../../modules/pubsub"
  project                                 = var.project
  subscription_endpoint                   = "${module.cloud-run-tagger.service_endpoint}/tagging-dispatcher-handler"
  subscription_name                       = "${var.tagger_pubsub_sub}_for_dispatcher"
  subscription_service_account            = google_service_account.sa_tagger_tasks.email
  topic                                   = "${var.tagger_pubsub_topic}_for_dispatcher"
  // DLP service account must be able to publish messages to the Tagger
  topic_publishers_sa_emails              = [google_service_account.sa_tagging_dispatcher.email]
  # 10m is max allowed
  subscription_ack_deadline_seconds       = var.tagger_subscription_ack_deadline_seconds
  # How long to retain unacknowledged messages in the subscription's backlog, from the moment a message is published.
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions
  subscription_message_retention_duration = var.tagger_subscription_message_retention_duration
}

### Data Catalog Policy Tags ####
module "data-catalog" {
  count = length(local.taxonomies_to_be_created)
  source = "../../modules/data-catalog"
  project = var.project
  region = local.taxonomies_to_be_created[count.index][0]

  domain = local.taxonomies_to_be_created[count.index][1]
  taxonomy_number = local.taxonomies_to_be_created[count.index][2]

  // only use the nodes that are marked for taxonomy number x
  classification_taxonomy = [for x in var.classification_taxonomy: x if x["taxonomy_number"] == local.taxonomies_to_be_created[count.index][2]]

  data_catalog_taxonomy_activated_policy_types = var.data_catalog_taxonomy_activated_policy_types
  taxonomy_name_suffix = var.taxonomy_name_suffix
}

############## Service Accounts ######################################

resource "google_service_account" "sa_tagging_dispatcher" {
  project = var.project
  account_id = var.sa_tagging_dispatcher
  display_name = "Runtime SA for Tagging Dispatcher service"
}

resource "google_service_account" "sa_tagger" {
  project = var.project
  account_id = var.sa_tagger
  display_name = "Runtime SA for Tagger service"
}

resource "google_service_account" "sa_tagging_dispatcher_tasks" {
  project = var.project
  account_id = var.sa_tagging_dispatcher_tasks
  display_name = "To authorize PubSub Push requests to Tagging Dispatcher Service"
}

resource "google_service_account" "sa_tagger_tasks" {
  project = var.project
  account_id = var.sa_tagger_tasks
  display_name = "To authorize PubSub Push requests to Tagger Service"
}

############## Service Accounts Access ################################

# Use google_project_iam_member because it's Non-authoritative.
# It Updates the IAM policy to grant a role to a new member.
# Other members for the role for the project are preserved.


#### Dispatcher Tasks Permissions ###

resource "google_service_account_iam_member" "sa_tagging_dispatcher_account_user_sa_dispatcher_tasks" {
  service_account_id = google_service_account.sa_tagging_dispatcher.name
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.sa_tagging_dispatcher_tasks.email}"
}

#### Dispatcher SA Permissions ###

locals {
  tagging_dispatcher_sa_roles = [
    "roles/bigquery.jobUser", #  to submit query jobs
    "roles/bigquery.dataEditor",
  ]

  tagger_sa_roles = [
    "roles/artifactregistry.reader", # to read container image for the service
    "roles/datacatalog.viewer", # to "get" solution-owned taxonomies created in that project
    "roles/bigquery.dataEditor", # to read data from dlp results table and views created inside the solution-managed dataset and writing to dispatcher_runs
  ]

  dlp_sa_roles = [
    "roles/datacatalog.categoryFineGrainedReader", # read BigQuery columns tagged by solution-managed taxonomies
    "roles/bigquery.dataEditor" # write results to BigQuery table inside of the solution dataset
  ]
}

resource "google_project_iam_member" "sa_dispatcher_roles_binding" {
  count = length(local.tagging_dispatcher_sa_roles)
  project = var.project
  role = local.tagging_dispatcher_sa_roles[count.index]
  member = "serviceAccount:${google_service_account.sa_tagging_dispatcher.email}"
}


#### Tagger Tasks SA Permissions ###

resource "google_service_account_iam_member" "sa_tagger_account_user_sa_tagger_tasks" {
  service_account_id = google_service_account.sa_tagger.name
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.sa_tagger_tasks.email}"
}

#### Tagger SA Permissions ###

resource "google_project_iam_member" "sa_tagger_roles_binding" {
  count = length(local.tagger_sa_roles)
  project = var.project
  role = local.tagger_sa_roles[count.index]
  member = "serviceAccount:${google_service_account.sa_tagger.email}"
}

############## DLP Service Account ################################################

resource "google_project_iam_member" "sa_dlp_roles_binding" {
  count = length(local.dlp_sa_roles)
  project = var.project
  role = local.dlp_sa_roles[count.index]
  member = "serviceAccount:${local.dlp_service_account_email}"
}

## Data Catalog Taxonomies Permissions ##


locals {

  # For each parent tag: omit the tag_id and lookup the list of IAM members to grant access to
  parent_tags_with_members_list = [for parent_tag in local.created_parent_tags:
  {
    policy_tag_name = parent_tag["id"]
    # lookup the iam_mapping variable with the key <domain> and then sub-key <classification>
    # parent_tag.display_name is the classification

    # if no iam_mapping is provided, then assign an empty list of IAM members for that tag,
    # if not, get the configured IAM members for the classification level of that tag
    iam_members = length(var.iam_mapping) == 0? [] : lookup(
      // the domain-specific IAM mapping entry
      var.iam_mapping[parent_tag["domain"]],
      // The parent tag classification used as the display name
      parent_tag["display_name"],
      // if no IAM list is found for that domain-classification, use an empty list for iam members
      []
    )

  }]

  // flatten the iam_members list inside of parent_tags_with_members_list
  iam_members_list = flatten([for entry in local.parent_tags_with_members_list:[
  for member in lookup(entry, "iam_members", "NA"):
  {
    policy_tag_name = lookup(entry, "policy_tag_name", "NA")
    iam_member = member
  }
  ]])
}

# Grant permissions for every member in the iam_members_list
resource "google_data_catalog_policy_tag_iam_member" "policy_tag_reader" {
  provider = google
  count = length(local.iam_members_list)
  policy_tag = local.iam_members_list[count.index]["policy_tag_name"]
  role = "roles/datacatalog.categoryFineGrainedReader"
  member = local.iam_members_list[count.index]["iam_member"]
}

# Helper functions for data analysis

resource "google_firestore_database" "datastore_mode_database" {
  project                           = var.project
  name                              = var.datastore_database_name
  location_id                       = var.compute_region
  type                              = "DATASTORE_MODE"
  concurrency_mode                  = "OPTIMISTIC"
  app_engine_integration_mode       = "DISABLED"
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_DISABLED"
  delete_protection_state           = "DELETE_PROTECTION_DISABLED"
  deletion_policy                   = "DELETE"
}

module "bq-remote-func-get-table-policy-tags" {
  source                         = "../../modules/bq-remote-function"
  function_name                  = var.bq_remote_func_get_policy_tags_name
  cloud_function_src_dir         = "../helpers/bq-remote-functions/get-policy-tags"
  cloud_function_temp_dir        = "/tmp/get-policy-tags.zip"
  service_account_name           = var.sa_bq_remote_func_get_policy_tags
  function_entry_point           = "process_request"
  // add more env_variables using merge({key=value}, {key=value}, etc}
  env_variables                  = {"DATASTORE_CACHE_DB_NAME" = var.datastore_database_name}
  project                        = var.project
  compute_region                 = var.compute_region
  data_region                    = var.data_region
  bigquery_dataset_name          =var.bigquery_dataset_name
  deployment_procedure_path      = "modules/bq-remote-function/procedures/deploy_get_policy_tags_remote_func.tpl"
  cloud_functions_sa_extra_roles = ["roles/datastore.user"]
}

### GCS buckets access

resource "google_storage_bucket_iam_member" "gcs_flags_bucket_iam_member_sa_tagging_dispatcher" {
  bucket = var.gcs_flags_bucket_name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.sa_tagging_dispatcher.email}"
}

resource "google_storage_bucket_iam_member" "gcs_flags_bucket_iam_member_sa_tagger" {
  bucket = var.gcs_flags_bucket_name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.sa_tagger.email}"
}

resource "google_storage_bucket_iam_member" "gcs_resource_bucket_iam_member_sa_tagger" {
  bucket = var.resources_bucket_name
  role = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.sa_tagger.email}"
}



####### Workflows


resource "google_service_account" "sa_workflows_bq" {
  project = var.project
  account_id = var.sa_workflows_bq
  display_name = "Runtime SA for Cloud Workflow for BigQuery Dispatcher"
}

resource "google_workflows_workflow" "bq_tagging_dispatcher_workflow" {

  project  = var.project
  name     = var.workflows_bq_name
  description = var.workflows_bq_description
  region = var.compute_region

  service_account = google_service_account.sa_workflows_bq.email

  deletion_protection = false

  source_contents = <<-EOF
main:
  params: [input]
  steps:
    - init:
        assign:
          - project: '${var.project}'
          - topic: '${module.pubsub-tagging-dispatcher.topic-id}'
          - message:
              projectsRegex: $${default(map.get(input, "projectsRegex"), ".*")}
              datasetsRegex: $${default(map.get(input, "datasetsRegex"), ".*")}
              tablesRegex: $${default(map.get(input, "tablesRegex"), ".*")}
          - base64Msg: '$${base64.encode(json.encode(message))}'
    - publish_message_to_topic:
        call: googleapis.pubsub.v1.projects.topics.publish
        args:
          topic: '$${topic}'
          body:
            messages:
              - data: '$${base64Msg}'
        result: publish_result
    - return_result:
        return:
          message_id: '$${publish_result.messageIds[0]}'
EOF
}

####### DLP  Configs

module "bq_dlp_configs" {
  source = "../../modules/dlp-bq-discovery-config"

  count = length(var.dlp_bq_discovery_configurations)

  dlp_bq_scan_org_id                                       = var.dlp_bq_scan_org_id

  dlp_bq_table_regex                                       = var.dlp_bq_discovery_configurations[count.index].table_regex
  dlp_bq_table_types = var.dlp_bq_discovery_configurations[count.index].table_types
  dlp_bq_apply_tags                                        = var.dlp_bq_discovery_configurations[count.index].apply_tags
  dlp_bq_create_configuration_in_paused_state              = var.dlp_bq_discovery_configurations[count.index].create_configuration_in_paused_state
  dlp_bq_dataset_regex                                     = var.dlp_bq_discovery_configurations[count.index].dataset_regex
  dlp_bq_project_id_regex                                  = var.dlp_bq_discovery_configurations[count.index].project_id_regex
  dlp_bq_reprofile_on_inspection_template_update_frequency = var.dlp_bq_discovery_configurations[count.index].reprofile_frequency_on_inspection_template_update
  dlp_bq_reprofile_on_schema_update_types = var.dlp_bq_discovery_configurations[count.index].reprofile_types_on_schema_update
  dlp_bq_reprofile_on_table_data_update_frequency          = var.dlp_bq_discovery_configurations[count.index].reprofile_frequency_on_table_data_update
  dlp_bq_reprofile_on_table_data_update_types = var.dlp_bq_discovery_configurations[count.index].reprofile_types_on_table_data_update
  dlp_bq_reprofile_on_table_schema_update_frequency        = var.dlp_bq_discovery_configurations[count.index].reprofile_frequency_on_table_schema_update
  dlp_bq_scan_folder_id                                    = var.dlp_bq_discovery_configurations[count.index].folder_id


  auto_dlp_results_table_name                              = var.auto_dlp_results_table_name
  bigquery_dataset_name                                    = var.bigquery_dataset_name
  data_region                                              = var.data_region
  dlp_inspection_templates_ids_list = var.dlp_inspection_templates_ids_list
  dlp_tag_high_sensitivity_id                              = var.dlp_tag_high_sensitivity_id
  dlp_tag_low_sensitivity_id                               = var.dlp_tag_low_sensitivity_id
  dlp_tag_moderate_sensitivity_id                          = var.dlp_tag_moderate_sensitivity_id
  project                                                  = var.project
  pubsub_tagger_topic_id                                   = module.pubsub-tagger-for-dlp.topic-id
}