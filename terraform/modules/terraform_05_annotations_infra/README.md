# Module - Annotations Infra
<!-- TOC -->
* [Module - Annotations Infra](#module---annotations-infra)
  * [Common Variables](#common-variables)
    * [Configure Basic Variables](#configure-basic-variables)
    * [Configure Cloud Run Service Image](#configure-cloud-run-service-image)
    * [Configure Data Classification Taxonomy](#configure-data-classification-taxonomy)
      * [Dealing with InfoType Count Limitation](#dealing-with-infotype-count-limitation)
      * [Dealing with Mixed PII](#dealing-with-mixed-pii)
    * [Configure Dry-Run labels options](#configure-dry-run-labels-options)
    * [Configure data deletion protection](#configure-data-deletion-protection)
    * [Configure overwriting existing labels (optional)](#configure-overwriting-existing-labels-optional)
  * [BigQuery-Discovery-Specific variables](#bigquery-discovery-specific-variables)
    * [Configure Dry-Run Tags option](#configure-dry-run-tags-option)
    * [Configure policy tags taxonomies enforcement](#configure-policy-tags-taxonomies-enforcement)
    * [Configure Domain Mapping (Optional)](#configure-domain-mapping-optional)
    * [Configure domain-IAM mapping (Optional)](#configure-domain-iam-mapping-optional)
    * [Configure what to do with Mixed PII](#configure-what-to-do-with-mixed-pii)
<!-- TOC -->

## Common Variables

### Configure Basic Variables

```terraform
application_project = "<GCP project to host the application internal resources (e.g. DLP, Cloud Run, Service Accounts, etc)>"
publishing_project = "<GCP project to host external/shared resources such as DLP results and monitoring views>"
compute_regions = "<GCP region to deploy compute resources (e.g. Cloud Run)>"
data_region = "<GCP region to store application data (e.g. logs, buckets, etc)>"
source_data_regions  = ["<Source data regions where policy tags taxonomies will be deployed to tag BigQuery tables in that regions>>"]
```

### Configure Cloud Run Service Image

Earlier, we built a container image that will be used by services of this
solution, and we pushed it to an artifact registry that we created for this
solution. In this step, we instruct Terraform to use that image in the Cloud Run
services that it will create.

PS: Terraform will just "link" a Cloud Run to an existing image. It will not
build the images from the codebase (thisis already done in a previous step)

```terraform
gar_docker_repo_name = "annotations"
services_container_image_name = "annotations-services:latest"
```

### Configure Data Classification Taxonomy

A mapping between DLP Info Types (Standard and Custom), policy tags and
classifications. Classifications are parent nodes in the taxonomy to group
children nodes.

```terraform

classification_taxonomy = [
  # example for built-in info types
  {
    info_type = "EMAIL_ADDRESS",
    info_type_category = "Standard",
    policy_tag = "email",
    classification = "P1",
    # optional fields
    labels   = [{ key = "contains_email_pii", value = "true"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  {
    info_type = "PHONE_NUMBER",
    info_type_category = "Standard",
    policy_tag = "phone"
    classification = "P2",
    # optional fields
    labels   = [{ key = "contains_phones_pii", value = "true"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  # example for custom info types (created in previous variables)
  {
    info_type = "CUSTOM_PAYMENT_METHOD",
    info_type_category = "Custom Dictionary",
    policy_tag = "payment_method"
    classification = "P1",
    # optional fields
    labels   = [{ key = "contains_custom_pii", value = "true"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  {
    info_type = "CUSTOM_EMAIL",
    info_type_category = "Custom Regex",
    policy_tag = "custom_email"
    classification = "P2",
    # optional fields
    labels   = [{ key = "contains_custom_pii", value = "true"}],
    inspection_template_number = 1,
    taxonomy_number            = 1
  },
  # special place holder for fields with multiple info types detected by DLP
  {
    info_type = "MIXED",
    info_type_category = "Custom",
    policy_tag = "mixed_pii"
    classification = "P1",
    # optional fields
    labels   = [{ key = "contains_mixed_pii", value = "true"}]
    inspection_template_number = 1,
    taxonomy_number            = 1
  },

  .. etc
  ]
```

This will enable the solution to:

*   Build hierarchical policy tag taxonomies
*   To identify which policy tag to apply to a column
*   To identify which labels to apply to a table or bucket

| Field                        | Required | Description                       |
| ---------------------------- | -------- | --------------------------------- |
| `classifications`            | Yes      | are parent nodes in the taxonomy  |
:                              :          : to group children nodes.          :
| `info_type_category`         | Yes      | is either "standard" or "custom". |
| `labels`                     | No       | list of resource labels to be     |
:                              :          : applied to tables where a certain :
:                              :          : PII is detected                   :
| `inspection_template_number` | No       | to deploy N DLP inspection        |
:                              :          : templates for scalability.        :
:                              :          : Explained in the next section     :
| `taxonomy_number`            | No       | to deploy N policy tag taxonomies |
:                              :          : for scalability. Explained in the :
:                              :          : next section                      :

#### Dealing with InfoType Count Limitation

There are two GCP limits that one could hit in defining taxonomies:

*   Max number of elements in a single taxonomy is 100 (including parent and
    children nodes)
*   Max number of custom InfoTypes per inspection template is 30

in order to get around those, the solution might need to deploy more than 1
taxonomy and/or more than 1 DLP inspection template. For that, the optional
`inspection_template_number` and `taxonomy_number` fields are used:

*   `inspection_template_number` default value is `1`. It means that this
    particular InfoType will be created in the Nth inspection template. This is
    needed if more than 30 custom InfoTypes are required, otherwise use `1`.

*   `taxonomy_number` default value is `1`. It means that this particular Policy
    Tag will be created in the Nth Cloud Data Catalog Taxonomy. This is needed
    of more than 100 nodes are to be created, otherwise use `1`. For a better
    visibility, try to locate all nodes under one parent (i.e. classification)
    in the same taxonomy.

#### Dealing with Mixed PII

DLP might find that one field contains multiple InfoTypes (e.g. free text
fields). Since we can only assign one policy tag to a column we need to have a
special placeholder for such fields. \
This placeholder is yet another entry in the classification taxonomy with
info_type = "MIXED". Users can configure the policy tag name and classification
level associated to it, but the `info_type` field can't be changed. This "MIXED"
InfoType is a special flag used by the solution and not a standard or custom DLP
Info Type.

```terraform
  {
    info_type = "MIXED",
    info_type_category = "Custom",
    policy_tag = "mixed_pii"
    classification = "P1",
    # optional fields
    labels   = [{ key = "contains_mixed_pii", value = "true"}]
    inspection_template_number = 1,
    taxonomy_number            = 1
  }
```

### Configure Dry-Run labels options

By setting `is_dry_run_labels = true` the solution will not attach the
configured resource labels in `classification_taxonomy` to the inspected
resources (buckets and BQ tables) and will only write log messages that can be
monitored via the `v_log_label_history` and `v_log_label_history_gcs` BigQuery
views.

```terraform
is_dry_run_labels = false
```

### Configure data deletion protection

Set to `true` in a prod env to avoid accidental deletion of DLP exports to
BigQuery by terraform apply

```terraform
terraform_data_deletion_protection = true
```

### Configure overwriting existing labels (optional)

This is a regex to identify and delete/overwrite existing resource labels on
buckets or tables that are previously created by the solution. This behaviour is
useful when the latest DLP findings doesn't include previously assigned labels
anymore due to changes in configuration or changes in underlying data.

```terraform
existing_labels_regex = "^contains_category_"
```

Alternatively, Omit the variable to use its default value that doesn't
match/delete any existing labels.

Recommended to omit this variable in early runs to avoid overwriting any
existing labels by mistake.

## BigQuery-Discovery-Specific variables

If you have set the `dlp_bq_discovery_configurations` variables in the `DLP`,
you also need to go through the following variables to configure the policy tags
actions.

### Configure Dry-Run Tags option

By setting `is_dry_run_tags = true` the solution will scan BigQuery tables for
PII data, store the scan result, but it will not apply policy tags to columns.
Instead, the "Tagger" function will only create log messages that can be
monitored via the `v_log_tag_history` monitoring view.

```terraform
is_dry_run_tags = false
```

### Configure policy tags taxonomies enforcement

Even if policy tags are attached to columns, there is still an option to enforce
access control via the tag or to bypass it. Set this variable to
`["FINE_GRAINED_ACCESS_CONTROL"]` to enforce access control via policy tags. Set
to `[]` bypass.

```terraform
data_catalog_taxonomy_activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
```

### Configure Domain Mapping (Optional)

A one-to-one mapping between GCP projects and/or BigQuery datasets and domains.
Domains are logical groupings that determine access control boundaries. For
example, if “Marketing” and “Finance” are domains this means that marketing PII
readers can only read their PII data but can't read finance PII data.

For each configured “domain” a corresponding taxonomy will be generated in Cloud
Data Catalog. Each taxonomy will contain the policy tags defined in InfoType -
Policy Tag Mapping in the hierarchy defined in Terraform (adjustable)

You can define one domain per project that will be applied to all BigQuery
tables inside it. Additionally, you can overwrite this default project domain on
dataset level (e.g. in case of a DWH project having data from different
domains).

```terraform

domain_mapping = [
  {
    project = "marketing-project",
    domain = "marketing"
  },
  {
    project = "dwh-project",
    domain = "dwh"
    datasets = [
      {
        name = "demo_marketing",
        domain = "marketing"
      },
      {
        name = "demo_finance",
        domain = "finance"
      }
    ]
  }
]
```

Omit this variable, or set to `domain_mapping = []` to use one default global
domain under the hood.

### Configure domain-IAM mapping (Optional)

A mapping between domains/classifications and IAM users and/or groups. This will
determine who has access to PII data under each domain and classification.

This is a dictionary of dictionaries. The first dict is in the format " domain =
dict" while the second level of dicts are in the format of "classification =
[list of IAM members]" where "domain" are the ones defined in `domain_mapping`
and "classification" are the ones configured in `classification_taxonomy`.

The format for IAM members is as follows:

*   For users: "user:username@example.com"
*   For groups: "group:groupname@example.com"
*   For service accounts: "serviceAccount:saname@example.com"

For example:

```terraform

iam_mapping = {

  marketing = {
    P1 = ["user:marketing-p1-reader@example.com"],
    P2 = ["user:marketing-p2-reader@example.com"]
  },

  finance = {
    P1 = ["user:finance-p1-reader@example.com"],
    P2 = ["user:finance-p2-reader@example.com"]
  },

  dwh = {
    P1 = ["user:dwh-p1-reader@example.com"],
    P2 = ["user:dwh-p2-reader@example.com"]
  }
}

```

Omit this variable, or set to `iam_mapping = {}`, to skip adding IAM members to
policy tag taxonomies (e.g. if the solution is in dry-run mode
`is_dry_run_tags`)

### Configure what to do with Mixed PII

The `promote_dlp_other_matches` setting will determine how the solution picks
only one info type and policy tag per column for the ones that have multiple
infotypes detected by DLP.

*   In case of `true`: \
    The solution will include the `other_matches` that DLP detects for a
    particular column to promote one policy tag per column. If a main info type
    is detected, then it will be used. Else, if only one "other matches" is
    found, it will be used. Otherwise, If more than one Info Type is detected in
    "other matches", "MIXED" policy tag will be applied to that column.
*   In case of `false`: \
    The solution will only rely on the main info type detected by DLP, or none
    if DLP doesn't report one.

```
promote_dlp_other_matches = false
```
