
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic

resource "google_pubsub_topic" "topic" {
  project = var.project
  name = var.topic
}

resource "google_pubsub_subscription" "subscription" {
  project = var.project
  name = var.subscription_name
  topic = google_pubsub_topic.topic.name

  ack_deadline_seconds = 30

  expiration_policy {
    # Never Expires. Empty to avoid the 31 days expiration.
    ttl = ""
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
  project = var.project
  topic = google_pubsub_topic.topic.id
  role = "roles/pubsub.publisher"
  member = "serviceAccount:${var.topic_publisher_sa_email}"
}
