module "apis" {
  source = "../../modules/terraform_00_apis"

  application_project             = var.application_project
  publishing_project              = var.publishing_project
}