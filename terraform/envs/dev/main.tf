module "apis" {
  source = "../../modules/terraform_00_apis"

  application_project = var.application_project
  publishing_project  = var.publishing_project
}

module "iam_on_host_project" {
  source = "../../modules/terraform_01_iam_host_project"

  application_project = var.application_project

  depends_on = [module.apis]
}

module "iam_on_publishing_project" {
  source = "../../modules/terraform_02_iam_publishing_project"

  application_project = var.application_project
  publishing_project  = var.publishing_project

  depends_on = [module.apis]
}

module "dlp" {
  source = "../../modules/terraform_03_dlp"

  org_id                             = var.org_id
  application_project                = var.application_project
  publishing_project                 = var.publishing_project
  data_region                        = var.data_region
  source_data_regions                = var.source_data_regions
  terraform_data_deletion_protection = var.terraform_data_deletion_protection

  deploy_dlp_inspection_template_to_global_region = true

  dlp_tag_sensitivity_level_key_name = "dlp_sensitivity_level_4"

  built_in_info_types = [
    {
      info_type = "EMAIL_ADDRESS"
    },
    {
      info_type = "PHONE_NUMBER"
    },
    {
      info_type = "STREET_ADDRESS"
    },
    {
      info_type = "PERSON_NAME"
    },
  ]

  custom_info_types_dictionaries = [
    {
      name       = "CUSTOM_PAYMENT_METHOD"
      likelihood = "LIKELY"
      dictionary = ["Debit Card", "Credit Card"]
    }
  ]

  custom_info_types_regex = [
    {
      name       = "CUSTOM_EMAIL"
      likelihood = "LIKELY"
      regex      = "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}"
    }
  ]

  dlp_bq_discovery_configurations = [
    {
      folder_id                                         = 11357726785,
      project_id_regex                                  = "^bqsc-marketing-v1$"
      dataset_regex                                     = "^marketing_us$"
      table_regex                                       = ".*"
      apply_tags                                        = true
      create_configuration_in_paused_state              = false
      table_types = ["BIG_QUERY_TABLE_TYPE_TABLE", "BIG_QUERY_TABLE_TYPE_EXTERNAL_BIG_LAKE"]
      reprofile_frequency_on_table_schema_update        = "UPDATE_FREQUENCY_NEVER"
      reprofile_frequency_on_table_data_update          = "UPDATE_FREQUENCY_NEVER"
      reprofile_frequency_on_inspection_template_update = "UPDATE_FREQUENCY_NEVER"
      reprofile_types_on_schema_update = ["SCHEMA_NEW_COLUMNS"]
      reprofile_types_on_table_data_update = ["TABLE_MODIFIED_TIMESTAMP"]
    },
    {
      folder_id                            = 490673413823
      create_configuration_in_paused_state = false
    }
  ]

  dlp_gcs_discovery_configurations = [
    {
      folder_id                                         = 11357726785
      project_id_regex                                  = "^bqsc-marketing-v1$"
      bucket_name_regex                                 = ".*"
      apply_tags                                        = true
      create_configuration_in_paused_state              = false
      reprofile_frequency                               = "UPDATE_FREQUENCY_NEVER"
      reprofile_frequency_on_inspection_template_update = "UPDATE_FREQUENCY_NEVER"
      included_bucket_attributes = ["ALL_SUPPORTED_BUCKETS"]
      included_object_attributes = ["ALL_SUPPORTED_OBJECTS"]
    },
    {
      folder_id                            = 490673413823
      create_configuration_in_paused_state = false
    }
  ]

  depends_on = [module.apis, module.iam_on_host_project, module.iam_on_publishing_project]
}

module "annotations-solution" {
  source = "../../modules/terraform_04_annotations_infra"

  application_project = var.application_project
  publishing_project  = var.publishing_project
  data_region         = var.data_region
  source_data_regions = var.source_data_regions
  compute_region      = var.compute_region
  terraform_data_deletion_protection = var.terraform_data_deletion_protection
  services_container_image_name = var.services_container_image_name

  # Linked variables. One can also omit and use the defaults assuming that they are in-sync across modules
  dlp_dataset_name = module.dlp.dlp_results_dataset
  application_service_account_name = module.iam_on_host_project.sa_application_name
  tagger_bq_service_account_name = module.iam_on_host_project.sa_tagger_bq_name
  tagger_gcs_service_account_name = module.iam_on_host_project.sa_tagger_gcs_name
  dlp_for_bq_pubsub_topic_name     = module.dlp.dlp_bq_notifications_topic
  dlp_for_gcs_pubsub_topic_name    = module.dlp.dlp_gcs_notifications_topic

  classification_taxonomy = [

    # Standard Types

    # source mapping: https://docs.google.com/spreadsheets/d/1ITe9yyN-Po0jD-9G6HR3RaEuGVmceXfkbiyyqV76e_I/edit?gid=621409567#gid=621409567

    # TODO: these info types are only available in the GLOBAL DLP region
    # { info_type = "LOCATION", info_type_category = "Standard", policy_tag = "location", classification = "Location", labels = [{ key = "dg_data_category_location", value = "yes"}], taxonomy_number = 1, inspection_template_number = 1 },
    # { info_type = "ORGANIZATION_NAME", info_type_category = "Standard", policy_tag = "organization_name", classification = "PII", labels = [{ key = "dg_data_category_pii", value = "yes"}], taxonomy_number = 1, inspection_template_number = 1 },

    # TODO: these info types don't exist in DLP
    # { info_type = "FINGERPRINT", info_type_category = "Standard", policy_tag = "fingerprint", classification = "Biometric", labels = [{ key = "dg_data_category_biometric", value = "yes"}], taxonomy_number = 1, inspection_template_number = 1 },
    # { info_type = "IRIS_SCAN", info_type_category = "Standard", policy_tag = "iris_scan", classification = "Biometric", labels = [{ key = "dg_data_category_biometric", value = "yes"}], taxonomy_number = 1, inspection_template_number = 1 },
    # { info_type = "RETINA_SCAN", info_type_category = "Standard", policy_tag = "retina_scan", classification = "Biometric", labels = [{ key = "dg_data_category_biometric", value = "yes"}], taxonomy_number = 1, inspection_template_number = 1 },
    # { info_type = "VOICEPRINT", info_type_category = "Standard", policy_tag = "voiceprint", classification = "Biometric", labels = [{ key = "dg_data_category_biometric", value = "yes"}], taxonomy_number = 1, inspection_template_number = 1 },
    # { info_type = "JOB_TITLE", info_type_category = "Standard", policy_tag = "job_title", classification = "Employee", labels = [{ key = "dg_data_category_employee", value = "yes"}], taxonomy_number = 1, inspection_template_number = 1 },
    # { info_type = "SALARY", info_type_category = "Standard", policy_tag = "salary", classification = "Employee", labels = [{ key = "dg_data_category_employee", value = "yes"}], taxonomy_number = 1, inspection_template_number = 1 },
    # { info_type = "EMPLOYEE_ID", info_type_category = "Standard", policy_tag = "employee_id", classification = "Employee", labels = [{ key = "dg_data_category_employee", value = "yes"}], taxonomy_number = 1, inspection_template_number = 1 },
    # { info_type = "USER_ID", info_type_category = "Standard", policy_tag = "user_id", classification = "PII", labels = [{ key = "dg_data_category_pii", value = "yes"}], taxonomy_number = 1, inspection_template_number = 1 },

    {
      info_type                                                                        = "IP_ADDRESS",
      info_type_category                                                               = "Standard",
      policy_tag                                                                       = "ip_address",
      classification                                                                   = "Location",
      labels = [{ key = "dg_data_category_location", value = "yes" }], taxonomy_number = 1,
      inspection_template_number                                                       = 1
    },
    {
      info_type                                                                        = "LOCATION_COORDINATES",
      info_type_category                                                               = "Standard",
      policy_tag                                                                       = "location_coordinates",
      classification                                                                   = "Location",
      labels = [{ key = "dg_data_category_location", value = "yes" }], taxonomy_number = 1,
      inspection_template_number                                                       = 1
    },
    {
      info_type       = "STREET_ADDRESS", info_type_category = "Standard", policy_tag = "street_address",
      classification  = "Location",
      labels = [{ key = "dg_data_category_location", value = "yes" }, { key = "dg_data_category_pii", value = "yes" }],
      taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                         = "AMERICAN_BANKERS_CUSIP_ID",
      info_type_category                                                                = "Standard",
      policy_tag                                                                        = "american_bankers_cusip_id",
      classification                                                                    = "Financial",
      labels = [{ key = "dg_data_category_financial", value = "yes" }], taxonomy_number = 1,
      inspection_template_number                                                        = 1
    },
    {
      info_type      = "CREDIT_CARD_NUMBER", info_type_category = "Standard", policy_tag = "credit_card_number",
      classification = "Financial", labels = [
      { key = "dg_data_category_financial", value = "yes" },
      { key = "dg_data_category_payment_instrument", value = "yes" }
    ], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type  = "CREDIT_CARD_TRACK_NUMBER", info_type_category = "Standard",
      policy_tag = "credit_card_track_number", classification = "Financial", labels = [
      { key = "dg_data_category_financial", value = "yes" },
      { key = "dg_data_category_payment_instrument", value = "yes" }
    ], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                         = "FINANCIAL_ACCOUNT_NUMBER",
      info_type_category                                                                = "Standard",
      policy_tag                                                                        = "financial_account_number",
      classification                                                                    = "Financial",
      labels = [{ key = "dg_data_category_financial", value = "yes" }], taxonomy_number = 1,
      inspection_template_number                                                        = 1
    },
    {
      info_type                                                                         = "IBAN_CODE",
      info_type_category                                                                = "Standard",
      policy_tag                                                                        = "iban_code",
      classification                                                                    = "Financial",
      labels = [{ key = "dg_data_category_financial", value = "yes" }], taxonomy_number = 1,
      inspection_template_number                                                        = 1
    },
    {
      info_type                                                                         = "SWIFT_CODE",
      info_type_category                                                                = "Standard",
      policy_tag                                                                        = "swift_code",
      classification                                                                    = "Financial",
      labels = [{ key = "dg_data_category_financial", value = "yes" }], taxonomy_number = 1,
      inspection_template_number                                                        = 1
    },
    {
      info_type                                                                         = "VAT_NUMBER",
      info_type_category                                                                = "Standard",
      policy_tag                                                                        = "vat_number",
      classification                                                                    = "Financial",
      labels = [{ key = "dg_data_category_financial", value = "yes" }], taxonomy_number = 1,
      inspection_template_number                                                        = 1
    },
    {
      info_type                                                                         = "VEHICLE_IDENTIFICATION_NUMBER",
      info_type_category                                                                = "Standard",
      policy_tag                                                                        = "vehicle_identification_number",
      classification                                                                    = "Financial",
      labels = [{ key = "dg_data_category_financial", value = "yes" }], taxonomy_number = 1,
      inspection_template_number                                                        = 1
    },
    {
      info_type                                                                      = "BLOOD_TYPE",
      info_type_category                                                             = "Standard",
      policy_tag                                                                     = "blood_type",
      classification                                                                 = "Health",
      labels = [{ key = "dg_data_category_health", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type       = "DATE_OF_BIRTH", info_type_category = "Standard", policy_tag = "date_of_birth",
      classification  = "Health",
      labels = [{ key = "dg_data_category_health", value = "yes" }, { key = "dg_data_category_pii", value = "yes" }],
      taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                      = "ICD10_CODE",
      info_type_category                                                             = "Standard",
      policy_tag                                                                     = "icd10_code",
      classification                                                                 = "Health",
      labels = [{ key = "dg_data_category_health", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                      = "ICD9_CODE",
      info_type_category                                                             = "Standard",
      policy_tag                                                                     = "icd9_code",
      classification                                                                 = "Health",
      labels = [{ key = "dg_data_category_health", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                      = "MEDICAL_RECORD_NUMBER",
      info_type_category                                                             = "Standard",
      policy_tag                                                                     = "medical_record_number",
      classification                                                                 = "Health",
      labels = [{ key = "dg_data_category_health", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                      = "MEDICAL_TERM",
      info_type_category                                                             = "Standard",
      policy_tag                                                                     = "medical_term",
      classification                                                                 = "Health",
      labels = [{ key = "dg_data_category_health", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                  = "ADVERTISING_ID", info_type_category = "Standard", policy_tag = "advertising_id",
      classification             = "PII", labels = [{ key = "dg_data_category_pii", value = "yes" }],
      taxonomy_number            = 1,
      inspection_template_number = 1
    },
    {
      info_type                                                                   = "AGE",
      info_type_category                                                          = "Standard", policy_tag = "age",
      classification                                                              = "PII",
      labels = [{ key = "dg_data_category_pii", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                   = "EMAIL_ADDRESS",
      info_type_category                                                          = "Standard",
      policy_tag                                                                  = "email_address",
      classification                                                              = "PII",
      labels = [{ key = "dg_data_category_pii", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                   = "ETHNIC_GROUP",
      info_type_category                                                          = "Standard",
      policy_tag                                                                  = "ethnic_group",
      classification                                                              = "PII",
      labels = [{ key = "dg_data_category_pii", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                   = "FIRST_NAME",
      info_type_category                                                          = "Standard",
      policy_tag                                                                  = "first_name",
      classification                                                              = "PII",
      labels = [{ key = "dg_data_category_pii", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                   = "GENDER",
      info_type_category                                                          = "Standard", policy_tag = "gender",
      classification                                                              = "PII",
      labels = [{ key = "dg_data_category_pii", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                   = "LAST_NAME",
      info_type_category                                                          = "Standard",
      policy_tag                                                                  = "last_name",
      classification                                                              = "PII",
      labels = [{ key = "dg_data_category_pii", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                  = "MARITAL_STATUS", info_type_category = "Standard", policy_tag = "marital_status",
      classification             = "PII", labels = [{ key = "dg_data_category_pii", value = "yes" }],
      taxonomy_number            = 1,
      inspection_template_number = 1
    },
    {
      info_type                                                                   = "PASSPORT",
      info_type_category                                                          = "Standard", policy_tag = "passport",
      classification                                                              = "PII",
      labels = [{ key = "dg_data_category_pii", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                   = "PERSON_NAME",
      info_type_category                                                          = "Standard",
      policy_tag                                                                  = "person_name",
      classification                                                              = "PII",
      labels = [{ key = "dg_data_category_pii", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                   = "PHONE_NUMBER",
      info_type_category                                                          = "Standard",
      policy_tag                                                                  = "phone_number",
      classification                                                              = "PII",
      labels = [{ key = "dg_data_category_pii", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                   = "TIME",
      info_type_category                                                          = "Standard", policy_tag = "time",
      classification                                                              = "PII",
      labels = [{ key = "dg_data_category_pii", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                   = "URL",
      info_type_category                                                          = "Standard", policy_tag = "url",
      classification                                                              = "PII",
      labels = [{ key = "dg_data_category_pii", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                                    = "ARGENTINA_DNI_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "argentina_dni_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "AUSTRALIA_DRIVERS_LICENSE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "australia_drivers_license_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "AUSTRALIA_MEDICARE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "australia_medicare_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "AUSTRALIA_PASSPORT",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "australia_passport",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "AUSTRALIA_TAX_FILE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "australia_tax_file_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "BELGIUM_NATIONAL_ID_CARD_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "belgium_national_id_card_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "BRAZIL_CPF_NUMBER", info_type_category = "Standard", policy_tag = "brazil_cpf_number",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "CANADA_BANK_ACCOUNT",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "canada_bank_account",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "CANADA_BC_PHN",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "canada_bc_phn",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "CANADA_DRIVERS_LICENSE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "canada_drivers_license_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "CANADA_OHIP",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "canada_ohip",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "CANADA_PASSPORT", info_type_category = "Standard", policy_tag = "canada_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "CANADA_QUEBEC_HIN", info_type_category = "Standard", policy_tag = "canada_quebec_hin",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "CANADA_SOCIAL_INSURANCE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "canada_social_insurance_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "CHILE_CDI_NUMBER", info_type_category = "Standard", policy_tag = "chile_cdi_number",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "CHINA_PASSPORT", info_type_category = "Standard", policy_tag = "china_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "CHINA_RESIDENT_ID_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "china_resident_id_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "COLOMBIA_CDC_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "colombia_cdc_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "CROATIA_PERSONAL_ID_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "croatia_personal_id_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "DENMARK_CPR_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "denmark_cpr_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "FINLAND_NATIONAL_ID_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "finland_national_id_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "FRANCE_CNI",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "france_cni",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "FRANCE_NIR",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "france_nir",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "FRANCE_PASSPORT", info_type_category = "Standard", policy_tag = "france_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "FRANCE_TAX_IDENTIFICATION_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "france_tax_identification_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "GERMANY_DRIVERS_LICENSE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "germany_drivers_license_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "GERMANY_IDENTITY_CARD_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "germany_identity_card_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "GERMANY_PASSPORT", info_type_category = "Standard", policy_tag = "germany_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "GERMANY_SCHUFA_ID", info_type_category = "Standard", policy_tag = "germany_schufa_id",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "GERMANY_TAXPAYER_IDENTIFICATION_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "germany_taxpayer_identification_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "HONG_KONG_ID_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "hong_kong_id_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "INDIA_AADHAAR_INDIVIDUAL",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "india_aadhaar_individual",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "INDIA_GST_INDIVIDUAL",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "india_gst_individual",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "INDIA_PAN_INDIVIDUAL",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "india_pan_individual",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "INDONESIA_NIK_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "indonesia_nik_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "IRELAND_DRIVING_LICENSE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "ireland_driving_license_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "IRELAND_EIRCODE", info_type_category = "Standard", policy_tag = "ireland_eircode",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "IRELAND_PASSPORT", info_type_category = "Standard", policy_tag = "ireland_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "IRELAND_PPSN",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "ireland_ppsn",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "ISRAEL_IDENTITY_CARD_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "israel_identity_card_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "ITALY_FISCAL_CODE", info_type_category = "Standard", policy_tag = "italy_fiscal_code",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "JAPAN_BANK_ACCOUNT",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "japan_bank_account",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "JAPAN_DRIVERS_LICENSE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "japan_drivers_license_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "JAPAN_INDIVIDUAL_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "japan_individual_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "JAPAN_PASSPORT", info_type_category = "Standard", policy_tag = "japan_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "KOREA_PASSPORT", info_type_category = "Standard", policy_tag = "korea_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "KOREA_RRN",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "korea_rrn",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "MEXICO_CURP_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "mexico_curp_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "MEXICO_PASSPORT", info_type_category = "Standard", policy_tag = "mexico_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "NETHERLANDS_BSN_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "netherlands_bsn_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "NETHERLANDS_PASSPORT",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "netherlands_passport",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "NEW_ZEALAND_IRD_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "new_zealand_ird_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "NORWAY_NI_NUMBER", info_type_category = "Standard", policy_tag = "norway_ni_number",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "PARAGUAY_CIC_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "paraguay_cic_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "PERU_DNI_NUMBER", info_type_category = "Standard", policy_tag = "peru_dni_number",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "POLAND_NATIONAL_ID_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "poland_national_id_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "POLAND_PASSPORT", info_type_category = "Standard", policy_tag = "poland_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "POLAND_PESEL_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "poland_pesel_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "PORTUGAL_CDC_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "portugal_cdc_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "PORTUGAL_NIB_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "portugal_nib_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "PORTUGAL_SOCIAL_SECURITY_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "portugal_social_security_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "SCOTLAND_COMMUNITY_HEALTH_INDEX_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "scotland_community_health_index_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "SINGAPORE_NATIONAL_REGISTRATION_ID_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "singapore_national_registration_id_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "SINGAPORE_PASSPORT",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "singapore_passport",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "SOUTH_AFRICA_ID_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "south_africa_id_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "SPAIN_CIF_NUMBER", info_type_category = "Standard", policy_tag = "spain_cif_number",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "SPAIN_DNI_NUMBER", info_type_category = "Standard", policy_tag = "spain_dni_number",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "SPAIN_DRIVERS_LICENSE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "spain_drivers_license_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "SPAIN_NIE_NUMBER", info_type_category = "Standard", policy_tag = "spain_nie_number",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "SPAIN_NIF_NUMBER", info_type_category = "Standard", policy_tag = "spain_nif_number",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "SPAIN_PASSPORT", info_type_category = "Standard", policy_tag = "spain_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "SPAIN_SOCIAL_SECURITY_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "spain_social_security_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "SWEDEN_NATIONAL_ID_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "sweden_national_id_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "SWEDEN_PASSPORT", info_type_category = "Standard", policy_tag = "sweden_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "TAIWAN_PASSPORT", info_type_category = "Standard", policy_tag = "taiwan_passport",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "THAILAND_NATIONAL_ID_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "thailand_national_id_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "TURKEY_ID_NUMBER", info_type_category = "Standard", policy_tag = "turkey_id_number",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "UK_DRIVERS_LICENSE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "uk_drivers_license_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "UK_ELECTORAL_ROLL_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "uk_electoral_roll_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "UK_NATIONAL_HEALTH_SERVICE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "uk_national_health_service_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "UK_NATIONAL_INSURANCE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "uk_national_insurance_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "UK_PASSPORT",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "uk_passport",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "UK_TAXPAYER_REFERENCE",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "uk_taxpayer_reference",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "URUGUAY_CDI_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "uruguay_cdi_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_ADOPTION_TAXPAYER_IDENTIFICATION_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_adoption_taxpayer_identification_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_BANK_ROUTING_MICR",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_bank_routing_micr",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_DEA_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_dea_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_DRIVERS_LICENSE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_drivers_license_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_EMPLOYER_IDENTIFICATION_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_employer_identification_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type       = "US_HEALTHCARE_NPI", info_type_category = "Standard", policy_tag = "us_healthcare_npi",
      classification  = "SPII", labels = [{ key = "dg_data_category_spii", value = "yes" }],
      taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_INDIVIDUAL_TAXPAYER_IDENTIFICATION_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_individual_taxpayer_identification_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_MEDICARE_BENEFICIARY_ID_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_medicare_beneficiary_id_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_PASSPORT",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_passport",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_PREPARER_TAXPAYER_IDENTIFICATION_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_preparer_taxpayer_identification_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_SOCIAL_SECURITY_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_social_security_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_STATE",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_state",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_TOLLFREE_PHONE_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_tollfree_phone_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "US_VEHICLE_IDENTIFICATION_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "us_vehicle_identification_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                                    = "VENEZUELA_CDI_NUMBER",
      info_type_category                                                           = "Standard",
      policy_tag                                                                   = "venezuela_cdi_number",
      classification                                                               = "SPII",
      labels = [{ key = "dg_data_category_spii", value = "yes" }], taxonomy_number = 2, inspection_template_number = 1
    },
    {
      info_type                                                            = "AUTH_TOKEN",
      info_type_category                                                   = "Standard", policy_tag = "auth_token",
      classification                                                       = "Other",
      labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                  = "AWS_CREDENTIALS", info_type_category = "Standard", policy_tag = "aws_credentials",
      classification             = "Other", labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1,
      inspection_template_number = 1
    },
    {
      info_type                  = "AZURE_AUTH_TOKEN", info_type_category = "Standard", policy_tag = "azure_auth_token",
      classification             = "Other", labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1,
      inspection_template_number = 1
    },
    {
      info_type                  = "BASIC_AUTH_HEADER", info_type_category = "Standard",
      policy_tag                 = "basic_auth_header",
      classification             = "Other", labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1,
      inspection_template_number = 1
    },
    {
      info_type                                                            = "COUNTRY_DEMOGRAPHIC",
      info_type_category                                                   = "Standard",
      policy_tag                                                           = "country_demographic",
      classification                                                       = "Other",
      labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                            = "GCP_API_KEY",
      info_type_category                                                   = "Standard", policy_tag = "gcp_api_key",
      classification                                                       = "Other",
      labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                  = "GCP_CREDENTIALS", info_type_category = "Standard", policy_tag = "gcp_credentials",
      classification             = "Other", labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1,
      inspection_template_number = 1
    },
    {
      info_type                                                            = "GENERIC_ID",
      info_type_category                                                   = "Standard", policy_tag = "generic_id",
      classification                                                       = "Other",
      labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                            = "HTTP_COOKIE",
      info_type_category                                                   = "Standard", policy_tag = "http_cookie",
      classification                                                       = "Other",
      labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                  = "HTTP_USER_AGENT", info_type_category = "Standard", policy_tag = "http_user_agent",
      classification             = "Other", labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1,
      inspection_template_number = 1
    },
    {
      info_type                                                            = "MAC_ADDRESS",
      info_type_category                                                   = "Standard", policy_tag = "mac_address",
      classification                                                       = "Other",
      labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                  = "MAC_ADDRESS_LOCAL", info_type_category = "Standard",
      policy_tag                 = "mac_address_local",
      classification             = "Other", labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1,
      inspection_template_number = 1
    },
    {
      info_type                                                            = "OAUTH_CLIENT_SECRET",
      info_type_category                                                   = "Standard",
      policy_tag                                                           = "oauth_client_secret",
      classification                                                       = "Other",
      labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                  = "SSL_CERTIFICATE", info_type_category = "Standard", policy_tag = "ssl_certificate",
      classification             = "Other", labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1,
      inspection_template_number = 1
    },
    {
      info_type                                                            = "STORAGE_SIGNED_POLICY_DOCUMENT",
      info_type_category                                                   = "Standard",
      policy_tag                                                           = "storage_signed_policy_document",
      classification                                                       = "Other",
      labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                            = "STORAGE_SIGNED_URL",
      info_type_category                                                   = "Standard",
      policy_tag                                                           = "storage_signed_url",
      classification                                                       = "Other",
      labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                            = "WEAK_PASSWORD_HASH",
      info_type_category                                                   = "Standard",
      policy_tag                                                           = "weak_password_hash",
      classification                                                       = "Other",
      labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },
    {
      info_type                                                            = "XSRF_TOKEN",
      info_type_category                                                   = "Standard", policy_tag = "xsrf_token",
      classification                                                       = "Other",
      labels = [{ key = "uncategorized", value = "yes" }], taxonomy_number = 1, inspection_template_number = 1
    },

    # Mixed
    {
      info_type                  = "MIXED",
      info_type_category         = "Custom",
      policy_tag                 = "mixed_pii",
      classification             = "PII",
      labels = [{ key = "dg_data_category_mixed", value = "yes" }],
      inspection_template_number = 1,
      taxonomy_number            = 1
    },
  ]

  depends_on = [module.iam_on_host_project]
}

module "org_iam" {
  source = "../../modules/terraform_05_iam_org_level"

  org_id                          = var.org_id
  application_project             = var.application_project

  # Linked variables. One can also omit and use the defaults assuming that they are in-sync across modules
  tagger_bq_service_account_name = module.iam_on_host_project.sa_tagger_bq_name
  tagger_gcs_service_account_name = module.iam_on_host_project.sa_tagger_gcs_name

  depends_on = [module.iam_on_host_project]
}

module "data_folders_iam" {
  source = "../../modules/terraform_06_iam_folder_level"

  org_id                          = var.org_id
  application_project             = var.application_project

  # use same folder ids configured in the DLP module dlp_bq_discovery_configurations & dlp_bq_discovery_configurations
  dlp_gcs_configurations_folders = module.dlp.dlp_gcs_folders
  dlp_bq_configurations_folders = module.dlp.dlp_bq_folders

  # Linked variables. One can also omit and use the defaults assuming that they are in-sync across modules
  tagger_bq_service_account_name   = module.iam_on_host_project.sa_tagger_bq_name
  tagger_gcs_service_account_name  = module.iam_on_host_project.sa_tagger_gcs_name
  tagger_bq_custom_role_id = module.org_iam.tagger_bq_custom_role_id
  tagger_gcs_custom_role_id = module.org_iam.tagger_gcs_custom_role_id

  depends_on = [module.iam_on_host_project, module.org_iam]
}

