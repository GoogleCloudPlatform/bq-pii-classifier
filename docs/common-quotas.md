## GCP Quotas

Inspector:
* DLP: 600 requests per min
* DLP: 1000 running jobs

Tagger:
* Maximum rate of dataset metadata update operations (including patch) 
* 5 operations every 10 seconds per dataset

Rate limiting for each service/step could be configured in the corresponding
PubSub push subscription via Terraform.