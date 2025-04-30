# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/data_loss_prevention_inspect_template

locals {

  dlp_region = var.region == "eu" ? "europe" : var.region
}

resource "google_data_loss_prevention_inspect_template" "inspection_template" {

  // create N templates based on the classification_taxonomy.inspection_template_number
  count = max([for x in var.built_in_info_types: x["inspection_template_number"]]...)

  parent = "projects/${var.project}/locations/${local.dlp_region}"
  description = "DLP Inspection template used by the BQ security classifier app"
  display_name = "bq_security_classifier_inspection_template_${count.index + 1}"

  # Info Types configured here must be mapped in the infoTypeName_policyTagName_map variable
  # passed to the main module, otherwise mapping to policy tags will fail.

  inspect_config {

    min_likelihood = "LIKELY"

    dynamic info_types {
      // filter the "standard" info types and the ones marked for the Nth template (while handling the zero-based offset)
      for_each = [for x in var.built_in_info_types: x if x["inspection_template_number"] == count.index+1]

      content {
        name = info_types.value["info_type"]
      }
    }

    ### CUSTOM INFO TYPES
    ## Limit is 30 Custom Info Types https://cloud.google.com/dlp/limits#custom-infotype-limits

    # Dictionary Custom Info Types
    dynamic custom_info_types {
      for_each = [for x in var.custom_info_types_dictionaries: x if x["inspection_template_number"] == count.index+1]
      content {
        info_type {
          name = custom_info_types.value["name"]
        }

        likelihood = custom_info_types.value["likelihood"]


        dictionary {
          word_list {
            words = custom_info_types.value["dictionary"]
          }
        }
      }
    }

    # Regex Custom Info Types
    dynamic custom_info_types {
      for_each = [for x in var.custom_info_types_regex: x if x["inspection_template_number"] == count.index+1]
      content {
        info_type {
          name = custom_info_types.value["name"]
        }

        likelihood = custom_info_types.value["likelihood"]

        regex {
          pattern = custom_info_types.value["regex"]
        }
      }
    }

    # to include findings text in the results table (e.g. user@domain.com -> EMAIL_ADDRESS)
    include_quote = false
  }
}