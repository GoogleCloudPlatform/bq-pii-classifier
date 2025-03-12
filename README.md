# BigQuery PII Classifier

## Overview

BigQuery PII Classifier is an OSS solution to automate the process of discovering and annotating
sensitive data across BigQuery tables and applying column-level access controls to restrict 
specific sensitive data types to certain users/groups in certain domains (e.g. business units).

![alt text](diagrams/main-architecture.png)


This version of the solution extends the discovery and annotation functionality to Google Cloud Storage using the
same flow. 

## Deployment

Follow the [deployment guide](docs/terraform-1-prepare.md) to configure and deploy the solution to Google Cloud Platform.

## Usage

After deploying the solution, there are two entry points of execution:

### DLP Events

This is an event-driven execution where DLP Discovery Service sends a pubsub notification
after it inspects a certain resource (i.e. table or bucket) and creates a data profile for it.

This notification is processed by the `Tagger` service and applies the configured annotations
(i.e. policy tags and/or resource labels) to the target resource based on DLP findings.

Note that one can't force-run DLP discovery service, so it might take time between the deployment
of the DLP discovery configuration and its scan.

### Tagging Dispatcher

The `Tagging Dispatcher` service is a mechanism to force-run the annotation process
on pre-existing DLP findings.

This could be used to invoke the annotation process without re-scanning data with DLP. For example:
* When annotation configuration has hanged (e.g. new labels, new classification level for policy tags, etc)
* When `Tagger` fails the first time due to missing permissions on certain data projects/folders

Cloud Workflows is used to manually invoke this process:
* In the host project, go to "Cloud Workflows"
* Open the BigQuery or GCS tagging dispatcher workflow
* Click the "Execute" button on top
* Inspect the annotation scope in the "message" field under "Code"
* To override the scope pass a JSON object with the attributes as the message in the "Input" tab
* * For example `{"projectsRegex": "^prod-", "bucketsRegex": ".*"}`
* Click the "Execute" button in the bottom


## Reporting

Check out this [document](docs/common-reporting.md) for example queries on:
* How to monitor execution steps
* How to detect broken execution steps (e.g. tables that were not tagged)
* Displaying a log of all tagging actions and sensitive data findings by the solution









