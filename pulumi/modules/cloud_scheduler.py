import pulumi
from pulumi_gcp import cloudscheduler
import json
import base64

from models.modules.cloud_scheduler_args import CloudSchedulerArgs

class CloudScheduler(pulumi.ComponentResource):
    def __init__(self, var: CloudSchedulerArgs, opts: None):
        super().__init__("custom:modules:CloudScheduler", "CloudScheduler", None, opts=opts)
        self.var = var
        self.__deploy()

    def __deploy(self):
        var = self.var

        scheduler_job = cloudscheduler.Job("scheduler_job",
                        project=var.project,
                        region=var.region,
                        name=var.scheduler_name,
                        description="CRON job to trigger BQ Security Classifier",
                        schedule=var.cron_expression,
                        retry_config={
                            "retry_count": 0
                        },
                        pubsub_target={
                            "topic_name": var.target_uri,
                            "data":  base64.b64encode(json.dumps({
                                "tables_include_list": var.tables_include_list,
                                "datasets_include_list": var.datasets_include_list,
                                "projects_include_list": var.projects_include_list,
                                "datasets_exclude_list": var.datasets_exclude_list,
                                "tables_exclude_list": var.tables_exclude_list,
                            }).encode() ).decode()
                        }, opts=pulumi.ResourceOptions(parent=self)
                        )
        self.register_outputs({
            "scheduler_job": scheduler_job.http_target
        })