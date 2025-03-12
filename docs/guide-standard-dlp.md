
### Terraform Deployment

Follow the steps in this [document](terraform-4-apply.md) and then continue here.

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
permissions on each data project. 

If you haven't configured Terraform to do that for you via the `data_projects_permissions_in_standard_mode` module in [Terraform](../terraform/03_main_option_bq_inspection_stack)
, you can grant these permissions manually with the following script:

From root folder:
```
./scripts/prepare_data_projects_for_standard_mode.sh <project1> <project2> <etc>
```

PS: 
* If you have tables to be inspected in the host project, run the above script and include the host project in the list
* Use the same projects list as set in the Terraform variable `projects_include_list`

## Manual Usage

### PII Inspection & Tagging Run

* In GCP, select the host project
* Go to Cloud Scheduler
* Trigger the "Inspection Scheduler"
* Inspect the status of the run via the queries in the [Reporting section](#reporting).  
  Alternatively you can check the logs of each Cloud Run service or just wait for few minutes.
* Inspect a sample BigQuery table and validate that the policy tags were applied correctly.    

PS: Inspection runs will have a `run_id` in the form `<timestamp>-i`  

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
