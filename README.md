# BigQuery PII Classifier

### Updates

* Cloud Data Loss Prevention (Cloud DLP) is now a part of Sensitive Data Protection. The API name remains the same: Cloud Data Loss Prevention API (DLP API). For information about the services that make up Sensitive Data Protection, see [Sensitive Data Protection overview](https://cloud.google.com/dlp/docs/sensitive-data-protection-overview).
* Automatic DLP (Auto-DLP) is now Sensitive Data Protection discovery service (aka. discovery service).

## Overview

BigQuery PII Classifier is an OSS solution to automate the process of discovering and tagging
PII data across BigQuery tables and applying column-level access controls to restrict 
specific PII data types to certain users/groups in certain domains (e.g. business units)
based on the confidentiality level of that PII.

![alt text](diagrams/summary.png)

Main Steps:

1. *Data Classification Taxonomy and User Access Configuration:*  
   Declare a taxonomy/hierarchy for PII types, and their confidentiality levels which can be modified and extended by customers to allow for custom PII types. 
2. *BigQuery Tables Inspection:*  
   Scan & automatically discover PII data based on the defined data classification taxonomy
3. *Columns Tagging:*  
   Applying access-control tags to columns in accordance with data classification 
4. *Enforcing Column-level Access Control:*  
    Limit PII data access to specific groups based on domains and data classification (e.g. Marketing High Confidentiality PII Readers, Finance Low Confidentiality PII Readers)  
    
<i>If you find this solution helpful please show us your support by <b>starring or forking</b> the repo and 
report issues using the Github tracker.  
If you're a Googler kindly fill in this short [survery](https://docs.google.com/forms/d/19D-3pocKKdDjFuaEoo_XBGoaRVGdbs_DAe35jbKcyyI/viewform)
for tracking and reach out to <b>bq-pii-classifier@</b> for support.</i> 

## Solution Modes
The solution comes with two modes, [standard-mode](docs/guide-standard-dlp.md) and [discovery-service-mode](docs/guide-discovery-service.md).

### Standard Mode

In standard-mode, the solution scope is:
* Automation of DLP inspection for tables (given an array of configurations)
* Applying policy tags to columns based on the PII types detected by the DLP inspection jobs
* Restricting access to the tagged columns based on the confidentiality level
* Possibility to trigger a "re-tagging" run that uses the last inspection results to overwrite the column policy tags.

For more details and on how to use the solution in `standard-mode` follow the [standard-mode guide](docs/guide-standard-dlp.md).

### Discovery Service Mode 

In discovery-service mode, the solution scope is:
* Not managing tables inspection, instead it will build on top of sensitive data discovery service (managed outside of the solution).
* Apply policy tags to columns based on the PII types detected by the discovery service.
* Restricting access to the tagged columns based on the confidentiality level

For more details and on how to use the solution in `discovery-service-mode` follow the [discovery-service-mode guide](docs/guide-discovery-service.md).

### Which mode to use?

Using `standard-mode` offers the following benefits:
* **Granular BigQuery scan scope**. Standard-mode could be configured to include/exclude projects, datasets and tables. Where in sensitive data discovery service, configurations 
are on Organization, folder and project levels. 
* **Control over DLP sampling size**. Standard-mode let you configure the DLP scan sample size as a function of the table size. For example, full scans of smaller tables
and sampling a lower percentage/number of records for bigger tables. This feature let you estimate and control DLP inspection cost to a higher degree.
* **Control over scan schedules**. Standard-mode enables you to call an entry-point service (i.e. Inspection Dispatcher) with different scan scopes on different schedules.
For example, historical dump tables could be scanned once every x month vs daily-refreshed tables could be scanned every x days.
* **On demand scans**. Standard-mode enables you to invoke an entry-point service on-demand. For example, after a data pipeline 
finishes you could trigger a call to scan only the table(s) affected by that pipeline.    

Using `discovery-service-mode` offers the following benefits:
* Relying on scalable, native GCP product for inspection/profiling.
* Relying on sensitive data discovery service heuristics to determine when to trigger a table scan. 
* Visualizing data profiles (i.e. tables, columns, PII types, metrics, etc) from the GCP console (UI).
* Accessing GCP Cloud Support for the product (sensitive data discovery service only, not this custom solution).

## Cost Control
The main contributing components to cost in this solution are DLP Inspection Jobs and BigQuery
Analytical Usage, where each component has its own cost control measures.

<b>For DLP:</b>  
    You can set the number or percentage of rows to be randomly selected 
and inspected from each table as a function of the table size. This is done in the Terraform
configuration as part of the deployment procedures. Please note that setting is only applicable
in the `standard-mode` while in `discovery-service-mode` it's up to the discovery service configurations and heuristics
to determine the frequency and number of rows to scan from each table.


<b>For BigQuery:</b>  
    It's important to understand that the solution (more specifically, the Tagger service)
will submit one query per target table in order to fetch its DLP findings,
interpret it and apply policy tags to that table. This query runs against a common DLP detailed
findings table that can grow large very quickly in runs that includes a large number of tables.
This in turn translates to more bytes scanned that contribute to higher costs.  

In order to factor in this point, it's highly advised to do one or more of the following if 
you plan to scan a large number of tables:
* Assign the solution host project to a BigQuery [Slot Reservation](https://cloud.google.com/bigquery/docs/reservations-intro) (Flat-Rate pricing)
* Create BigQuery [Custom Cost Controls](https://cloud.google.com/bigquery/docs/custom-quotas) to avoid scanning (and paying) more than a daily Threshold 

## Data Access Model Example
 
  Check out this [document](docs/common-iam-example.md) for an example on a data access
  model across domains and IAM group structure.

 ## Solution Limits
  
 Check out this [document](docs/common-limits.md) for solution limits.
 
 ## GCP Quotas
 
 Check out this [document](docs/common-quotas.md) for related GCP Quotas.