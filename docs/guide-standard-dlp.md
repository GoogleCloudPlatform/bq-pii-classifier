# BigQuery PII Classifier - Standard Mode

Table of content:
1. [Architecture](#architecture)
2. [Deployment](#deployment)
3. [Manual Usage](#manual-usage)
4. [Reporting](#reporting)
5. [Automated Usage](#automated-usage)

## Architecture

 ![alt text](../diagrams/standard%20mode-design.jpg)
 
 ### Components
 *Inspection Dispatcher Service*  
 A Cloud Run service that acts as an entry point for the solution. It expects a BigQuery scanning scope expressed as inclusion and exclusion lists of projects, datasets and tables. This scope could be one or more tables.  
 
 The Inspection Dispatcher will call the BigQuery API to list all tables included in the scan scope and submit a DLP Inspection request for that table in the Inspector Tasks topic.  
 
 *Inspector Tasks Topic*  
 This PubSub topic decouples the Inspection Dispatcher from the Inspector in order to handle the rate limits of the DLP API and to apply auto-retries with backoffs.  
 
 *Inspector Service*  
 A Cloud Run service that expects a request to scan one table. It will submit an Inspection job to DLP for that table according to the configured Inspection template and other parameters such as scan limits, results table, notifications topic, etc.  
 
 For cost control, the service will limit the number of rows to be scanned based on the table size and a user defined configuration that determines limit intervals (e.g. 0-1000 rows → sample 100, 1001-10000 → sample 500, etc). This sample will be taken randomly from the table.  
 
 *Tagger Tasks Topic*  
 This PubSub topic decouples the DLP API notifications from the Tagger service in order to handle the rate limits of BigQuery column tagging operations and to apply auto-retries with backoffs.  
 
 *Tagger Service*
 A Cloud Run service that expects the information of one BigQuery table. It will determine the InfoType of each column based on the latest DLP findings and apply the appropriate policy tag.
 
 *Tagging Dispatcher Service*  
 A Cloud Run service that acts as an entry point for the solution. It expects a BigQuery scope expressed as inclusion and exclusion lists of projects, datasets and tables. This scope could be one or more tables.    
  
 The Tagging Dispatcher will list all tables included in the scan scope that has existing DLP scan results and submit a table tagging request for that table in the Tagger Tasks topic.  
 
 This service is used to trigger a re-tagging run without re-inspecting the table. This is helpful in cases where the classification taxonomy has changed, but the underlying data is the same.   
  
 *BigQuery Config Views*  
 Terraform will generate config views based on the defined  mappings and configurations. These config views are mainly used by the Tagger service to determine the policy tagging logic.  
 
 *Logs*  
 All Cloud Run services are writing structured logs that are exported by a log sink to BigQuery. On top of that there are a number of BigQuery views that help in monitoring and debugging call chains and tagging actions on columns.  

## Deployment
### Environment Preparation

Follow the steps in this [document](common-terraform-1-prepare.md) and then continue here.

### Build Cloud Run Services Images

We need to build and deploy docker images to be used by the Cloud Run service.

```
export TAGGING_DISPATCHER_IMAGE=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO_NAME}/bqsc-tagging-dispatcher-service:latest
export INSPECTION_DISPATCHER_IMAGE=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO_NAME}/bqsc-inspection-dispatcher-service:latest
export INSPECTOR_IMAGE=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO_NAME}/bqsc-inspector-service:latest
export TAGGER_IMAGE=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO_NAME}/bqsc-tagger-service:latest


./scripts/deploy_common_services.sh

./scripts/deploy_inspection_services.sh

```

### Terraform Variables Configuration

The solution is deployed by Terraform and thus all configurations are done
on the Terraform side.

#### Configure common variables

Follow the steps in this [document](common-terraform-2-variables.md) and then continue here.

#### Configure Standard mode

Configure the solution NOT to be deployed in Auto DLP mode (i.e. standard mode). In standard mode,
the solution will be responsible for periodically scanning tables instead building on top of Auto DLP results.

```
is_auto_dlp_mode = false
```

#### Configure Cloud Run Service Images

Earlier, we used Docker to build container images that will be used by the solution.
In this step, we instruct Terraform to use these published images in the Cloud Run services
that Terraform will create. 

PS: Terraform will just "link" a Cloud Run to an existing image. It will not build the images from the code base (this 
is already done in a previous step)

```
tagging_dispatcher_service_image = "< value of env variable TAGGING_DISPATCHER_IMAGE >"
inspection_dispatcher_service_image = "< value of  env variable INSPECTOR_IMAGE >"
inspector_service_image = "< value of env variable INSPECTOR_IMAGE >"
tagger_service_image = "< value of env variable TAGGER_IMAGE >"
``` 

#### Configure Cloud Scheduler CRON

Configure the schedule on which the solution entry point(s) is invoked.  

The `inspection_cron_expression` sets the schedule on which the Inspection Dispatcher service will be invoked.  
This will trigger a scan of the BigQuery scope defined earlier and apply policy tags to column (unless it's run in dry_run mode). 
  
```
inspection_cron_expression = "0 0 * * *"
```
  
The `tagging_cron_expression` sets the schedule on which the Tagging Dispatcher service will be invoked.  
This will use the latest DLP findings (i.e. results of a previous Inspection scan) and re-apply the policy tags based on the latest
data classification taxonomy. This option is meant to be used "on-demand" in the standard mode and
it's recommended to pause it after deployment to avoid unnecessary runs.
  
```
tagging_cron_expression = "0 12 1 * *"
```
  
PS: the current solution has one entry point/scheduler but one can extend the solution
by adding more schedulers that have different BigQuery scope and/or timing.


#### Configure Table Scan Limits

This will define the scan limit of the DLP jobs when they inspect BigQuery tables. 
`limitType`: could be `NUMBER_OF_ROWS` or `PERCENTAGE_OF_ROWS`.
`limits`: key/value pairs of {interval_upper_limit, rows_to_sample}. For example,
`"limits": { "1000": "100" , "5000": "500"}` means that tables  with 0-1000
records will use a sample of 100 records, tables between 1001-5000 will sample 500 records
and tables 5001-INF will also use 500 records.

When using `PERCENTAGE_OF_ROWS` the rows_to_sample should be an integer between 1-100. For example,
20 means 20%.

```
table_scan_limits_json_config = "{\"limitType\": \"NUMBER_OF_ROWS\", \"limits\": {\"10000\": \"100\",\"100000\": \"5000\", \"1000000\": \"7000\"}}"
```

#### Configure what to do with Mixed PII 

The `promote_mixed_info_types` setting will determine how the solution picks only one InfoType and policy tag
for columns that have multiple InfoTypes detected by DLP.   

* In case of `false`:   
The solution will report the infotype of a column as "MIXED" if DLP finds more than one InfoType for that field (regardless of likelihood and number of findings)
* In case of `true`:    
The solution will compute a score for each reported InfoType based on signals like likelihood and number of findings and pick the InfoType with the highest score.
If the scores are still a tie, the solution will fallback to "MIXED" infoType.   

In both cases, columns with final reported InfoType "MIXED" will be mapped to the policy tag configured in the `classification_taxonomy`. 

Internally, this "promotion" logic is defined in a BigQuery view `v_dlp_findings`. There are two versions of this [view](terraform/modules/bigquery/views) and this variable
controls which one gets deployed by Terraform.  

```
promote_mixed_info_types = false
```

### Terraform Deployment

Follow the steps in this [document](common-terraform-3-apply.md) and then continue here.

### Post deployment setup

#### Set post-terraform env variables

Set the following variables that will be used in next steps:

```
export SA_TAGGING_DISPATCHER_EMAIL=tag-dispatcher@${PROJECT_ID}.iam.gserviceaccount.com
export SA_INSPECTION_DISPATCHER_EMAIL=insp-dispatcher@${PROJECT_ID}.iam.gserviceaccount.com
export SA_INSPECTOR_EMAIL=inspector@${PROJECT_ID}.iam.gserviceaccount.com
export SA_TAGGER_EMAIL=tagger@${PROJECT_ID}.iam.gserviceaccount.com
export SA_DLP_EMAIL=service-${PROJECT_NUMBER}@dlp-api.iam.gserviceaccount.com
```

PS: update the SA emails if the default names have been changed in Terraform


#### Configure Data Projects

The application is deployed under a host project as set in the `PROJECT_ID` variable.
To enable the application to tag columns in other projects (i.e. data projects) one must grant a number of
permissions on each data project. To do, run the following script:

From root folder:
```
./scripts/prepare_data_projects_for_standard_dlp_mode.sh <project1> <project2> <etc>
```

PS: 
* If you have tables to be inspected in the host project, run the above script and include the host project in the list
* Use the same projects list as set in the Terraform variable `projects_include_list`

## Manual Usage

### PII Inspection & Tagging Run

* In GCP, select the host project
* Go to Cloud Scheduler
* Trigger the "Inspection Scheduler"
* Inspect the status of the run via the queries in the [Reporting section](Reporting).  
  Alternatively you can check the logs of each Cloud Run service or just wait for few minutes.
* Inspect a sample BigQuery table and validate that the policy tags were applied correctly.    

PS: Re-tagging runs will have a `run_id` in the form `<timestamp>-i`  

### Re-tagging Run
Same as Inspection run but trigger the "Tagging Scheduler" instead.  

PS: Re-tagging runs will have a `run_id` in the form `<timestamp>-t`  

## Reporting

Check out this [document](common-reporting.md) for example queries on:
* How to monitor execution steps
* How to detect broken execution steps (e.g. tables that were not tagged)
* Displaying a log of all tagging actions and PII findings by the solution


## Automated Usage
 
After deploying the solution, one can call it in different ways:  
 
 
 **[Option 1] Inventory Scans:**    
 
  ![alt text](../diagrams/standard%20mode-usage-inventory%20scan.jpg)
 
 In this scenario, a BigQuery scan scope is defined to include several projects, datasets and tables to be inspected and tagged once or on a regular schedule. This could be done by using Cloud Scheduler (or any Orchestration tool) to invoke the Inspection Dispatcher service with such scan scope and frequency.  
 
 In addition, more than one Cloud Scheduler/Trigger could be defined to group tables that have the same inspection schedule (daily, monthly, etc)
 
 **[Option 2]  Immediate Scans:**  
 
 ![alt text](../diagrams/standard%20mode-usage-immediate%20scan.jpg)
 
 Within a data pipeline that populates X number of tables, one could invoke the Inspection Dispatcher service with a list of only these tables after the data load step. This could be done from the ETL, or the orchestration tool used.
 
**[Option 3]  Event-based Scans:**  
  
![alt text](../diagrams/standard%20mode-usage-event%20based%20scan.jpg)
   
One could listen to certain log-events on GCP via log sinks (e.g. BigQuery table load, Dataflow job completion) and trigger the Inspection Dispatcher service to inspect and tag the concerned table/tables.

## Updating DLP Info Types

Check out this [document](common-managing-dlp-types.md) for 
steps on how to add/remove Info Types in the classification taxonomy.
