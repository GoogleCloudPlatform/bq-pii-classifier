import pulumi
from pulumi_gcp import storage

class GoogleCloudStorage(pulumi.ComponentResource):
    def __init__(self, project_id, bucket_name, region, gcs_flags_bucket_admins, opts=None):
        super().__init__("custom:modules:GoogleCloudStorage", "GoogleCloudStorage", None, opts=opts)
        self.child_opts = pulumi.ResourceOptions(parent=self)
        self.project_id = project_id
        self.gcs_flags_bucket_name = bucket_name
        self.region = region
        self.gcs_flags_bucket_admins = gcs_flags_bucket_admins
        self.__deploy()
        
    def __deploy(self):

        var = self
        # Create GCS bucket resource
        self.gcs_flags_bucket = storage.Bucket(
        "gcs_flags_bucket",
        project=var.project_id,
        name=var.gcs_flags_bucket_name,
        location=var.region,
        lifecycle_rules=[
            storage.BucketLifecycleRuleArgs(
            condition=storage.BucketLifecycleRuleConditionArgs(age=3),
            action=storage.BucketLifecycleRuleActionArgs(type="Delete"),
            )
        ],
        uniform_bucket_level_access=True,
        opts=self.child_opts
        )
        self.gcs_flags_bucket_name = self.gcs_flags_bucket.name
        self.register_outputs({
            "gcs_flags_bucket_name": self.gcs_flags_bucket.name,
        })

    def setup_bucket_iam_admins(self, gcs_flags_bucket_admins):
        # Create IAM binding for GCS bucket
        print(gcs_flags_bucket_admins)
        gcs_flags_bucket_iam_binding = storage.BucketIAMBinding(
        "gcs_flags_bucket_iam_bindings",
        bucket=self.gcs_flags_bucket.name,
        role="roles/storage.objectAdmin",
        members=gcs_flags_bucket_admins,
        opts= pulumi.ResourceOptions(parent=self, depends_on=[self.gcs_flags_bucket])
        )
        

        