 ## Solution Limits
 
General limits:
  * Supports 1 GCP region only:  
  A table must be in the same GCP region as the taxonomy in order to use its policy tags. If tables
  span multiple regions, the solution must be extended to create replicas of the taxonomies in other regions
  and include them in the InfoType to policy tag mapping views created by Terraform.
  
 [Data Catalog Limits:](https://cloud.google.com/data-catalog/docs/resources/quotas)
 * 40 taxonomies per project --> 40 domains to configure in the domain mapping (1 taxonomy per domain)
 * 100 policy tags per taxonomy --> 100 data classifications and DLP types to scan for
 
 [BigQuery Limits:](https://cloud.google.com/bigquery/quotas)
 * 1 policy tag per column --> One column could be identified as only one DLP InfoType.
 