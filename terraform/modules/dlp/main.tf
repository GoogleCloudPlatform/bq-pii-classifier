# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/data_loss_prevention_inspect_template

locals {

  dlp_region = var.region == "eu" ? "europe" : var.region
}

resource "google_data_loss_prevention_inspect_template" "inspection_template" {

  // create N templates based on the classification_taxonomy.inspection_template_number
  count = max([for x in var.classification_taxonomy: x["inspection_template_number"]]...)

  parent = "projects/${var.project}/locations/${local.dlp_region}"
  description = "DLP Inspection template used by the BQ security classifier app"
  display_name = "bq_security_classifier_inspection_template_${count.index + 1}"

  # Info Types configured here must be mapped in the infoTypeName_policyTagName_map variable
  # passed to the main module, otherwise mapping to policy tags will fail.

  inspect_config {

    min_likelihood = "LIKELY"

    dynamic info_types {
      // filter the "standard" info types and the ones marked for the Nth template (while handling the zero-based offset)
      for_each = [for x in var.classification_taxonomy: x if lower(x["info_type_category"]) == "standard" && x["inspection_template_number"] == count.index+1]

      content {
        name = info_types.value["info_type"]
      }
    }

    ### CUSTOM INFOTYPES
    ## Limit is 30 Custom Info Types https://cloud.google.com/dlp/limits#custom-infotype-limits

    # Dictionary Custom Info Types
    dynamic custom_info_types {
      for_each = [for x in var.classification_taxonomy: x if lower(x["info_type_category"]) == "custom dictionary"
      && x["inspection_template_number"] == count.index+1]
      content {
        info_type {
          name = custom_info_types.value["info_type"]
        }
        likelihood =
          # search in the list for the object with name = xyz and then get the desired property from that object
          var.custom_info_types_dictionaries[index(var.custom_info_types_dictionaries[*].name,  custom_info_types.value["info_type"])]["likelihood"]
        dictionary {
          word_list {
            words =
              var.custom_info_types_dictionaries[index(var.custom_info_types_dictionaries[*].name,  custom_info_types.value["info_type"])]["dictionary"]
          }
        }
      }
    }

    # Regex Custom Info Types
    dynamic custom_info_types {
      for_each = [for x in var.classification_taxonomy: x if lower(x["info_type_category"]) == "custom regex"
      && x["inspection_template_number"] == count.index+1]
      content {
        info_type {
          name = custom_info_types.value["info_type"]
        }
        likelihood =
          # search in the list for the object with name = xyz and then get the desired property from that object
          var.custom_info_types_regex[index(var.custom_info_types_regex[*].name,  custom_info_types.value["info_type"])]["likelihood"]
        regex {
          pattern =
            var.custom_info_types_regex[index(var.custom_info_types_regex[*].name,  custom_info_types.value["info_type"])]["regex"]
        }
      }
    }

    #### RULE SETS

    # Example: Exclude a pattern of emails from the EMAIL_ADDRESS detector

#    rule_set {
#      info_types {
#        name = "EMAIL_ADDRESS"
#      }
#      rules {
#        exclusion_rule {
#          regex {
#            pattern = ".+@excluded-example.com"
#          }
#          matching_type = "MATCHING_TYPE_FULL_MATCH"
#        }
#      }
#    }


    #Example: Omit matches on PERSON_NAME detector if also matched by EMAIL_ADDRESS  detector
    # i.e. Don't report PERSON_NAME on a column that has EMAIL_ADDRESS matches
    # https://cloud.google.com/dlp/docs/creating-custom-infotypes-rules#omit_matches_on_person_name_detector_if_also_matched_by_email_address_detector

#    rule_set {
#      info_types {
#        name = "PERSON_NAME"
#      }
#      rules {
#        exclusion_rule {
#          exclude_info_types {
#            info_types {
#              name = "EMAIL_ADDRESS"
#            }
#          }
#          matching_type = "MATCHING_TYPE_FULL_MATCH"
#        }
#      }
#    }


    # Example: Increase likelihood for STREET_ADDRESS fields if the column name matches a pattern
    # https://cloud.google.com/dlp/docs/creating-custom-infotypes-likelihood#match-column-values

#    rule_set {
#      info_types {
#        name = "STREET_ADDRESS"
#      }
#      rules {
#        hotword_rule {
#          hotword_regex {
#            pattern = "(street_name|street_address|delivery_address|house_number|city|zip)"
#          }
#          proximity {
#            window_before = 1
#          }
#          likelihood_adjustment {
#            fixed_likelihood = "VERY_LIKELY"
#          }
#        }
#      }
#    }

    # to include findings text in the results table (e.g. user@domain.com -> EMAIL_ADDRESS)
    include_quote = false
  }
}