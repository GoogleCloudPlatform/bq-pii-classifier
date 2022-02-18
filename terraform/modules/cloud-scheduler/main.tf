
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_scheduler_job

resource "google_cloud_scheduler_job" "scheduler_job" {
  name             = var.scheduler_name
  description      = "CRON job to trigger BQ Security Classifier"
  schedule         = var.cron_expression

  retry_config {
    retry_count = 0
  }

  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = var.target_uri
    data       = base64encode(jsonencode({
      tableIncludeList = var.tables_include_list
      datasetIncludeList = var.datasets_include_list
      projectIncludeList = var.projects_include_list
      datasetExcludeList = var.datasets_exclude_list
      tableExcludeList = var.tables_exclude_list
    }))
  }
}




