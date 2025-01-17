output "created_inspection_templates" {
  value = {
    region = var.region
    ids = google_data_loss_prevention_inspect_template.inspection_template[*].id
  }
}

output "inspection_templates" {
  value = google_data_loss_prevention_inspect_template.inspection_template[*]
}

