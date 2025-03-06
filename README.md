# BigQuery PII Classifier

## Overview

BigQuery PII Classifier is an OSS solution to automate the process of discovering and tagging
sensitive data across BigQuery tables and applying column-level access controls to restrict 
specific sensitive data types to certain users/groups in certain domains (e.g. business units)
based on the confidentiality level of that sensitive data.

![alt text](diagrams/main-architecture.png)

The above is a temp diagram to explain the flow until full documentation and deployment guide is developed.

This version of the solution extends the discovery and labeling functionality to Google Cloud Storage as well using the
flow. The Terraform module deploys two stacks to do so: BIGQUERY_DISCOVERY and GCS_DISCOVERY