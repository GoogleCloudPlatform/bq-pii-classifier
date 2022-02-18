## Managing DLP Info Types

Steps to add/change an InfoType:
* Add InfoType to the [inspection_template](terraform/modules/dlp/main.tf)
* In your .tfvars file Add a mapping entry to variable classification_taxonomy
* Apply terraform (will create/update the inspection template)

