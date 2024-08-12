import pulumi
from models.modules.cloud_run_args import CloudRunArgs
from pulumi_gcp import cloudrun
import datetime

class CloudRunService(pulumi.ComponentResource):
    def __init__(self, var: CloudRunArgs, resource_name ,opts: None):
        super().__init__(f"custom:modules:CloudRunService{resource_name}", resource_name, opts=opts)
        self.var = var
        self.timestamp = datetime.datetime.now().strftime("%Y-%m-%d-%H:%M:%S")
        self.child_opts = pulumi.ResourceOptions(parent=self)
        self.__deploy()

    def __deploy(self):
        var = self.var
        service = cloudrun.Service(
        "service",
            project=var.project,
            name=var.service_name,
            location=var.region,
            template=cloudrun.ServiceTemplateArgs(
                spec=cloudrun.ServiceTemplateSpecArgs(
                timeout_seconds=var.timeout_seconds,
                service_account_name=var.service_account_email,
                container_concurrency=var.max_requests_per_container,
                containers=[
                    cloudrun.ServiceTemplateSpecContainerArgs(
                    image=var.service_image,
                    resources=cloudrun.ServiceTemplateSpecContainerResourcesArgs(
                        limits={
                        "memory": var.max_memory,
                        "cpu": var.max_cpu,
                        },
                    ),
                    envs=[
                        cloudrun.ServiceTemplateSpecContainerEnvArgs(
                        name=env.name,
                        value=env.value,
                        )
                        for env in var.environment_variables
                    ] + [
                        cloudrun.ServiceTemplateSpecContainerEnvArgs(
                        name="TERRAFORM_UPDATED_AT",
                        value=self.timestamp,
                        )
                    ],
                    )
                ],
                ),
                metadata=cloudrun.ServiceTemplateMetadataArgs(
                annotations={
                    "autoscaling.knative.dev/maxScale": var.max_containers,
                },
                ),
            ),
            metadata=cloudrun.ServiceMetadataArgs(
                annotations={
                "run.googleapis.com/ingress": "internal",
                },
            ),
            traffics=[
                cloudrun.ServiceTrafficArgs(
                percent=100,
                latest_revision=True,
                ),
            ],
            opts=self.child_opts
            )
        print(f"Service {self._name}")
        service.id.apply(lambda x: print(f"Service URL: {x}"))
        
        # Create the IAM member for the service account invoker
        sa_invoker = cloudrun.IamMember(
                "sa-invoker",
                project=service.project,
                location=service.location,
                service=service.name,
                role="roles/run.invoker",
                member=var.invoker_service_account_email.apply(lambda x: f"serviceAccount:{x}"),
                opts=self.child_opts
                )
        
        self.service_endpoint = service.statuses[0].url
        
        