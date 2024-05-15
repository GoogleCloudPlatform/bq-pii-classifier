## Managing DLP Info Types

Steps to add/change an InfoType:
* Add InfoType to the [inspection_template](../terraform/modules/dlp/main.tf)
* In your `.tfvars` file Add a mapping entry to the variable `classification_taxonomy`
* Deploy the Terraform (will create/update the inspection template)

