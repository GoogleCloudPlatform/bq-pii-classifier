# Configure project by setting below variables.


pulumi select stack a208571-deal-pii-clasifier-$ENV

pulumi config set project_id $PROJECT_ID
pulumi config set gcp:project $PROJECT_ID
pulumi config set compute-region $COMPUTE_REGION
pulumi config set data-region $DATA_REGION
pulumi config set domain $DOMAIN
pulumi config set project-number $PROJECT_NUMBER 
pulumi config set dlp-dataset-name $DLP_DATASET_NAME
pulumi config set gcs-flags-bucket-name $GCS_FLAGS_BUCKET_NAME