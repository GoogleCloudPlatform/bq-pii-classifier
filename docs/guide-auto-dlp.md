# BigQuery PII Classifier - Auto DLP Mode

Table of content:
1. [Architecture](#architecture)
2. [Deployment](#deployment)
3. [Manual Usage](#manual-usage)
4. [Reporting](#reporting)
5. [Automated Usage](#automated-usage)

## Architecture

 ![alt text](../diagrams/auto%20dlp-design.jpg)
 
 ### Components
 
 *Tagging Dispatcher Service:*  
A Cloud Run service that acts as an entry point for the solution. It expects a BigQuery scope expressed as inclusion and exclusion lists of projects, datasets and tables. This scope could be one or more tables.    
    
The Tagging Dispatcher will list all tables included in the scope that has existing Auto DLP data profiles and submit a table tagging request for that table in the Tagger Tasks topic.  
   
*Tagger Tasks Topic:*  
This PubSub topic decouples the Tagging Dispatcher from the Tagger service in order to handle the rate limits of BigQuery column tagging operations and to apply auto-retries with backoffs.  
  
*Tagger Service:*  
A Cloud Run service that expects the information of one BigQuery table. It will determine the InfoType of each column based on the latest DLP findings and apply the appropriate policy tag.
  
*BigQuery Config Views:*  
Terraform will generate config views based on the defined  mappings and configurations. These config views are mainly used by the Tagger service to determine the policy tagging logic.  
 
*Logs:*  
All Cloud Run services are writing structured logs that are exported by a log sink to BigQuery. On top of that there are a number of BigQuery views that help in monitoring and debugging call chains and tagging actions on columns.  

## Deployment

### Environment Preparation

Follow the steps in this [document](common-terraform-1-prepare.md) and then continue here.

### Build Cloud Run Services Images

We need to build and deploy docker images to be used by the Cloud Run service.

```
export TAGGING_DISPATCHER_IMAGE=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO_NAME}/bqsc-tagging-dispatcher-service:latest
export TAGGER_IMAGE=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO_NAME}/bqsc-tagger-service:latest

./scripts/deploy_common_services.sh
```

### Terraform Variables Configuration

The solution is deployed by Terraform and thus all configurations are done
on the Terraform side.

#### Configure common variables

Follow the steps in this [document](common-terraform-2-variables.md) and then continue here.

#### Configure Auto-DLP mode

Configure the solution to be deployed in Auto DLP mode 

```
is_auto_dlp_mode = true
```

#### Configure Cloud Run Service Images

Earlier, we used Docker to build container images that will be used by the solution.
In this step, we instruct Terraform to use these published images in the Cloud Run services
that Terraform will create. 

PS: Terraform will just "link" a Cloud Run to an existing image. It will not build the images from the code base (this 
is already done in a previous step)

```
tagging_dispatcher_service_image = "< value of env variable TAGGING_DISPATCHER_IMAGE >"
tagger_service_image = "< value of env variable TAGGER_IMAGE >"
``` 

#### Configure Auto-DLP results table

Configure the name of the inspection results table that will be used by Auto DLP.
Note this table name because it will be used while configuring Auto DLP outside of Terraform.
 
```
auto_dlp_results_table_name = "<table>"
```

#### Configure Cloud Scheduler CRON

Configure the schedule on which the solution entry point is invoked.  

The `tagging_cron_expression` sets the schedule on which the Tagging Dispatcher service will be invoked.  
This will use the latest DLP findings (i.e. results of Auto DLP) and apply the policy tags based on the latest
data classification taxonomy.
  
```
tagging_cron_expression = "0 0 * * *"
```
  
PS: the current solution has one entry point/scheduler but one can extend the solution
by adding more schedulers that have different BigQuery scope and/or timing.


### Terraform Deployment

Follow the steps in this [document](common-terraform-3-apply.md) and then continue here.


### Configure Auto DLP on GCP 

Follow the official [GCP guide](https://cloud.google.com/dlp/docs/data-profiles) 
on how to set up scan configurations. Please note the following sections:
* "Select inspection template": choose the "existing template" option 
  and use the template that is created by the solution via Terraform (found under DLP > Configuration > Templates).
  This will enable Auto DLP to look for the PII types you configured earlier in Terraform.
* "Manage scan outcome": enable "save data profile copies to BigQuery" and use the same project, dataset and auto_dlp_table_name configured/created by Terraform.

### Post deployment setup

#### Set env variables

Set the following variables that will be used in next steps:

```
export ENV=<same one set in terraform vars>
export SA_TAGGING_DISPATCHER_EMAIL=tag-dispatcher-${ENV}@${PROJECT_ID}.iam.gserviceaccount.com
export SA_TAGGER_EMAIL=tagger-${ENV}@${PROJECT_ID}.iam.gserviceaccount.com
```

PS: update the SA emails if the default names have been changed in Terraform


#### Configure Auto DLP Results Dataset

You can skip this step if you choose to configure Auto DLP to store the inspection results in the 
BigQuery dataset that was created by Terraform earlier.

Otherwise, you must grant permissions on the inspection results dataset to the deployed solution.

From root folder:
```
export AUTO_DLP_DATASET="<project.dataset.table>"

./scripts/prepare_auto_dlp_results_dataset.sh
```  

#### Configure Data Projects

The application is deployed under a host project as set in the `PROJECT_ID` variable.
To enable the application to tag columns in other projects (i.e. data projects) one must grant a number of
permissions on each data project. To do, run the following script:

From root folder:
```
./../scripts/prepare_data_projects_for_auto_dlp_mode.sh <project1> <project2> <etc>
```

PS: 
* If you have tables to be inspected in the host project, run the above script and include the host project in the list
* Use the same projects list as set in the Terraform variable `projects_include_list`

## Manual Usage

* In GCP, select the host project
* Go to Cloud Scheduler
* Trigger the "Tagging Scheduler"
* Inspect the status of the run via the queries in the [Reporting section](Reporting).  
  Alternatively you can check the logs of each Cloud Run service or just wait for few minutes.
* Inspect a sample BigQuery table and validate that the policy tags were applied correctly.   

## Reporting

Check out this [document](common-reporting.md) for example queries on:
* How to monitor execution steps
* How to detect broken execution steps (e.g. tables that were not tagged)
* Displaying a log of all tagging actions and PII findings by the solution


## Automated Usage

After deploying the solution, one can call it in different ways:
 
 **[Option 1] CRON Schedules:**    
 
  ![alt text](../diagrams/auto%20dlp-usage-cron.jpg)
 
 In this scenario, a BigQuery scan is defined to include several projects, datasets and tables to be tagged once or on a regular schedule. This could be done by using Cloud Scheduler (or any Orchestration tool) to invoke the Tagging Dispatcher service with such scan scope and frequency.  
 
 In addition, more than one Cloud Scheduler/Trigger could be defined to group tables that have the same inspection schedule (daily, monthly, etc)
 
 **[Option 2] [ROADMAP] Auto-DLP Notifications:**  
 
 ![alt text](../diagrams/auto%20dlp-usage-tagger%20notification.jpg)
 
 Once Auto DLP offers a feature to send PubSub notifications on job completion, these notifications could be sent to the Tagger Tasks Topic to trigger a tagging request for that table.
 This might need an extension in the solution code to handle the PubSub message format sent by Auto-DLP.   


## Updating DLP Info Types

Check out this [document](common-managing-dlp-types.md) for 
steps on how to add/remove Info Types in the classification taxonomy.


