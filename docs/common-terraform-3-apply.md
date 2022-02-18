
### Deploy solution via Terraform

```
cd terraform

terraform init \
    -backend-config="bucket=${BUCKET_NAME}" \
    -backend-config="prefix=terraform-state"

terraform workspace new $CONFIG
# or, if it's not the first deployment
terraform workspace select $CONFIG

terraform plan -var-file=$VARS

terraform apply -var-file=$VARS -auto-approve

```

PS: In case you're deploying to a new project where DLP has
never run before, the DLP service account won't be created and Terraform will fail.  
In that case, run a sample DLP job to force DLP to create the service account.
