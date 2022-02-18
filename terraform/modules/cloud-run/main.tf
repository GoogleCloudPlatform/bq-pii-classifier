#https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service

locals {
  timestamp = formatdate("YYYY-MM-DD-hh:mm:ss", timestamp())
}

resource "google_cloud_run_service" "service" {
  name = var.service_name
  location = var.region

  template {
    spec {

      timeout_seconds = 300
      service_account_name = var.service_account_email

      container_concurrency = var.max_requests_per_container

      containers {
        image = var.service_image

        resources {
          limits = {
            "memory": var.max_memory
            "cpu": var.max_cpu
          }
        }

        dynamic env {
          for_each = var.environment_variables
          content {
            name = env.value["name"]
            value = env.value["value"]
          }
        }


        # Hack to force terraform to re-deploy this service (e.g. update latest image)
        env {
          name = "TERRAFORM_UPDATED_AT"
          value = local.timestamp
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"  = var.max_containers
      }
    }

  }

  metadata {
    annotations = {
      "run.googleapis.com/ingress" : "internal"
    }
  }


  traffic {
    percent = 100
    latest_revision = true
  }
}

### Dispatcher Tasks SA must be able to invoke Dispatcher service ####
resource "google_cloud_run_service_iam_member" "sa_invoker" {

  project = google_cloud_run_service.service.project
  location = google_cloud_run_service.service.location
  service = google_cloud_run_service.service.name
  role = "roles/run.invoker"
  member = "serviceAccount:${var.invoker_service_account_email}"
}