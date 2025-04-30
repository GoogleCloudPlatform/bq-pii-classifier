## Deployment

### Prerequisites

#### Create a host project

Create a new project, or dedicate an existing one, to host the resources
and services used by this solution. This have the following implications:

* All **costs** incurred, including that of DLP scans, will be attributed to this project.
* Cloud DLP service account of this project will be used to scan data in other projects
* Some service accounts created by the solution under this project will need access to annotate resources in other projects
* DLP detailed findings will be stored in a bigquery dataset in that project
* For the `BIQUERY_DISCOVERY` stack, policy tags taxonomies that will be used for column level security automation will be created in this project

Due to the points mentioned above, it's recommended to use a dedicated project with
restricted user access to it.

#### Permissions on host project

Make sure that the user account running the below steps has `roles/admin` on the host project

### Environment setup

In a terminal shell, run the following commands:

```shell
export PROJECT_ID=<project id of the host project> 
export COMPUTE_REGION=< region to deploy infra resources >
export DATA_REGION=< region to deploy data resources e.g. bigquery dataset >

# GCS bucket to hold Terraform state
export BUCKET_NAME=${PROJECT_ID}-annotations
export BUCKET=gs://${BUCKET_NAME}
# Docker repo name to be created and used by the solution
export DOCKER_REPO_NAME=annotations
# Container image name that contains the services used by the solution
export IMAGE_NAME=${COMPUTE_REGION}-docker.pkg.dev/${PROJECT_ID}/${DOCKER_REPO_NAME}/annotations-services

# to auth and run deployment scripts
gcloud auth application-default login
```

### Enable APIs

Enable a list of APIs required for the next manual steps and to run Terraform

```shell
./scripts/enable_apis_for_terraform.sh 
```

PS: Terraform will enable more APIs programmatically

### Create Terraform State Bucket

```shell
gsutil mb -p $PROJECT_ID -l $COMPUTE_REGION -b on $BUCKET
```

### Prepare a Terraform Service Account

#### Create a Terraform Service Account in the host project

The following script creates a service account in the host project for Terraform and assigns the required project-level permissions on it:
```shell
# service account name to be created for Terraform in the host project
export TF_SA=terraform

./scripts/prepare_terraform_service_account_on_host_project.sh
```

#### Grant the Terraform Service Account Org Permissions

Terraform will deploy DLP discovery configs on the org node, and grant other service accounts
permissions to inspect and annotate the data assets. For that, the Terraform service
account needs to have certain org-level permissions to do so

```shell
./scripts/prepare_terraform_service_account_on_org.sh <ORGANIZATION_ID>
```

#### Use an existing Terraform Service Account (Optional)

Alternatively, you can skip this section and use an existing service account granted that it has the roles
and permissions defined in the following scripts 
* [host project permissions](../scripts/prepare_terraform_service_account_on_host_project.sh)
* [org permissions](../scripts/prepare_terraform_service_account_on_org.sh)

The external service account email will be used with Terraform at a later step

### Create a Docker Repo

We need a Docker repository to publish container images that are used by this solution

```shell
./scripts/prepare_docker_repo.sh
```

### Deploy the services container image

The solution uses a number of services that are containerized. We need to build and push that container image
before deploying Cloud Run via Terraform

```shell
./scripts/deploy_all_services_cloudbuild.sh
```

### Configure Terraform Variables File

Continue with Terraform configuration as explained in this guide [terraform-variables](terraform-2-variables.md)