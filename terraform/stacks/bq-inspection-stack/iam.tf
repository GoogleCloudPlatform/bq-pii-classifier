############## Service Accounts ######################################

resource "google_service_account" "sa_inspection_dispatcher" {
  project = var.project
  account_id = var.sa_inspection_dispatcher
  display_name = "Runtime SA for Inspection Dispatcher service"
}

resource "google_service_account" "sa_inspector" {
  project = var.project
  account_id = var.sa_inspector
  display_name = "Runtime SA for Inspector service"
}

resource "google_service_account" "sa_inspection_dispatcher_tasks" {
  project = var.project
  account_id = var.sa_inspection_dispatcher_tasks
  display_name = "To authorize PubSub Push requests to Inspection Dispatcher Service"
}

resource "google_service_account" "sa_inspector_tasks" {
  project = var.project
  account_id = var.sa_inspector_tasks
  display_name = "To authorize PubSub Push requests to Inspector Service"
}

############## Service Accounts Access ################################

# Use google_project_iam_member because it's Non-authoritative.
# It Updates the IAM policy to grant a role to a new member.
# Other members for the role for the project are preserved.


#### Dispatcher Tasks Permissions ###

resource "google_service_account_iam_member" "sa_inspection_dispatcher_account_user_sa_dispatcher_tasks" {
  service_account_id = google_service_account.sa_inspection_dispatcher_tasks.name
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.sa_inspection_dispatcher_tasks.email}"
}

#### Dispatcher SA Permissions ###

# Grant sa_dispatcher access to submit query jobs
resource "google_project_iam_member" "sa_inspection_dispatcher_bq_job_user" {
  project = var.project
  role = "roles/bigquery.jobUser"
  member = "serviceAccount:${google_service_account.sa_inspection_dispatcher.email}"
}


#### Inspector Tasks SA Permissions ###

resource "google_service_account_iam_member" "sa_inspector_account_user_sa_inspector_tasks" {
  service_account_id = google_service_account.sa_inspector.name
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.sa_inspector_tasks.email}"
}

#### Inspector SA Permissions ###

# Grant sa_inspector access to list dlp jobs
resource "google_project_iam_member" "sa_inspector_dlp_jobs_editor" {
  project = var.project
  role = "roles/dlp.jobsEditor"
  member = "serviceAccount:${google_service_account.sa_inspector.email}"
}

# Grant sa_inspector access to read dlp templates
resource "google_project_iam_member" "sa_inspector_dlp_template_reader" {
  project = var.project
  role = "roles/dlp.inspectTemplatesReader"
  member = "serviceAccount:${google_service_account.sa_inspector.email}"
}