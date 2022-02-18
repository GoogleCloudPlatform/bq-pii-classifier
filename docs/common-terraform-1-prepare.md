### Env setup

In a terminal shell, set and export the following variables.

```
export PROJECT_ID=<project to deploy to> 
export PROJECT_NUMBER=< get from GCP project home page>
export TF_SA=bq-pii-classifier-terraform
export COMPUTE_REGION=< region to deploy infra resources >
export DATA_REGION=< region where the target data resides >
export BUCKET_NAME=${PROJECT_ID}-bq-security-classifier
export BUCKET=gs://${BUCKET_NAME}
export DOCKER_REPO_NAME=docker-repo

export CONFIG=<gcloud & terraform config name> 
export ACCOUNT=< personal account email >  

gcloud config configurations create $CONFIG
gcloud config set project $PROJECT_ID
gcloud config set account $ACCOUNT
gcloud config set compute/region $COMPUTE_REGION
gcloud auth login

gcloud auth application-default login
```

### GCP Set up

* Enable App Engine API in the project and create an application (for cloud tasks and scheduler to work)
* Enable APIs
  * Enable [Cloud Resource Manager API](https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com)
  * Enable [IAM API](https://console.developers.google.com/apis/api/iam.googleapis.com/overview)
  * Enable [Data Catalog API](https://console.developers.google.com/apis/api/datacatalog.googleapis.com/overview)
  * Enable [Cloud Tasks API](https://console.developers.google.com/apis/api/cloudtasks.googleapis.com/overview)
  * Enable [Cloud Functions API](https://console.developers.google.com/apis/api/cloudfunctions.googleapis.com/overview)
  * Enable [Artifact Registry](https://console.developers.google.com/apis/api/artifactregistry.googleapis.com/overview) 


### Prepare Terraform State Bucket

```
gsutil mb -p $PROJECT_ID -l $COMPUTE_REGION -b on $BUCKET
```

### Prepare Terraform Service Account

Terraform needs to run with a service account to deploy DLP resources. User accounts are not enough.  

```
./scripts/prepare_terraform_service_account.sh
```

### Prepare a Docker Repo

We need a Docker Repository to publish images that are used by this solution

```
gcloud artifacts repositories create $DOCKER_REPO_NAME --repository-format=docker \
--location=$COMPUTE_REGION --description="Docker repository"
```