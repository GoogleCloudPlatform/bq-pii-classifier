output "service_endpoint" {
  value = google_cloud_run_service.service.status[0].url
}

