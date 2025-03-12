
### Deploy via Terraform

```
cd terraform

terraform init \
    -backend-config="bucket=${BUCKET_NAME}" \
    -backend-config="prefix=terraform-state"

terraform plan -var-file=$VARS

terraform apply -var-file=$VARS -auto-approve
```


