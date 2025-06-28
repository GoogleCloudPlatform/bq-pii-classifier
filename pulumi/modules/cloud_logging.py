import pulumi
from pulumi_gcp import logging, bigquery


class CloudLogging(pulumi.ComponentResource):
    def __init__(self, results_dataset_id :str, project_id :str , log_sink_name :str, opts: None):
        super().__init__("custom:modules:CloudLogging", log_sink_name, None, opts=opts)
        self.child_opts = pulumi.ResourceOptions(parent=self)
        self.project_id = project_id
        self.results_dataset_id = results_dataset_id
        self.log_sink_name = log_sink_name

        self.__deploy()

    def __deploy(self):
        log_sink = logging.ProjectSink(
        "bigquery-logging-sink",
        name=self.log_sink_name,
        destination=f"bigquery.googleapis.com/projects/{self.project_id}/datasets/{self.results_dataset_id}",
        filter="resource.type=cloud_run_revision jsonPayload.global_app=bq-pii-classifier",
        unique_writer_identity=True,
        bigquery_options={
            "use_partitioned_tables": True
        },
        opts=self.child_opts
        )

        self.register_outputs({
            "log_sink_service_account_writer_identity": log_sink.writer_identity
        })

        self.service_account = log_sink.writer_identity
        

      