
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic

resource "google_pubsub_topic" "topic" {
  project = var.project
  name = var.topic
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription

resource "google_pubsub_subscription" "subscription" {
  project = var.project
  name = var.subscription_name
  topic = google_pubsub_topic.topic.name

  # Use a relatively high value to avoid re-sending the message when the deadline expires.
  # Especially with the dispatchers that could take few minutes to list all tables for large scopes
  ack_deadline_seconds = var.subscription_ack_deadline_seconds

  # How long to retain unacknowledged messages in the subscription's backlog, from the moment a message is published.
  # In case of unexpected problems we want to avoid a buildup that re-trigger functions (e.g. Tagger issuing unnecessary BQ queries)
  # It also sets how long should we keep trying to process one run
  message_retention_duration = var.subscription_message_retention_duration
  retain_acked_messages = false

  enable_message_ordering  = false

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
    push_endpoint = var.subscription_endpoint

    oidc_token {
      service_account_email = var.subscription_service_account
    }
  }
}

# Allow an SA to publish to this topic
resource "google_pubsub_topic_iam_member" "sa_topic_publisher" {
  count = length(var.topic_publishers_sa_emails)
  project = var.project
  topic = google_pubsub_topic.topic.id
  role = "roles/pubsub.publisher"
  member = "serviceAccount:${var.topic_publishers_sa_emails[count.index]}"
}
