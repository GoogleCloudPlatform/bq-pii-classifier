output "templates_ids" {
  value = google_data_loss_prevention_inspect_template.inspection_template[*].id
}

output "inspection_templates" {
  value = google_data_loss_prevention_inspect_template.inspection_template[*]
}

