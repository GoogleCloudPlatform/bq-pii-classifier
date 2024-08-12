import pulumi
from models.modules.cloud_run_args import CloudRunArgs, EnvironmentVariable
from models.modules.cloud_scheduler_args import CloudSchedulerArgs
from models.modules.pubsub_args import PubSubArgs
from modules.cloud_scheduler import CloudScheduler
from models.stack.inspection_stack_args import InspectionStackArgs
from modules.cloud_run import CloudRunService
from modules.pubsub import PubSub
from .iam import IAM

class InspectionStack(pulumi.ComponentResource):
    def __init__(self, var: InspectionStackArgs,resource_name, opts: pulumi.ResourceOptions = None):
        super().__init__("custom:stack:InspectionStack", resource_name, None, opts)

        self.var = var 

    def deploy(self):
        iam = self.__setup_iam()
        cloud_run_inspection_dispatcher = self.__setup_cloud_run_inspection_dispatcher(iam)
        pubsub_inspection_dispatcher = self.__setup_pubsub_inspection_dispatcher(cloud_run_inspection_dispatcher, iam)

        self.__setup_cloud_scheduler(pubsub_inspection_dispatcher)

        cloud_run_inspector = self.__setup_cloud_run_inspector(iam)

        pubsub_inspector = self.__setup_pubsub_inspector(cloud_run_inspector, iam)

    def __setup_iam(self):
        iam = IAM("google_service_account",var= self.var)
        self.iam = iam
        return iam
    
    def __setup_cloud_scheduler(self, pubsub_inspection_dispatcher: PubSub):
        scheduler = CloudScheduler(var= CloudSchedulerArgs(
            project= self.var.project,
            region= self.var.compute_region,
            scheduler_name= self.var.scheduler_name,
            target_uri= pubsub_inspection_dispatcher.topic_id,

            tables_include_list= self.var.tables_include_list,
            datasets_include_list= self.var.datasets_include_list,
            projects_include_list= self.var.projects_include_list,
            
            datasets_exclude_list= self.var.datasets_exclude_list,
            tables_exclude_list= self.var.tables_exclude_list,
            cron_expression= self.var.cron_expression,

        ),opts= pulumi.ResourceOptions(parent= self, depends_on=[pubsub_inspection_dispatcher]))
        return scheduler
    
    def __setup_cloud_run_inspection_dispatcher(self, iam: IAM):
        cloud_run_inspection_dispatcher = CloudRunService(var= CloudRunArgs(
            project= self.var.project,
            region= self.var.compute_region,
            service_image= self.var.dispatcher_service_image,
            service_name= self.var.dispatcher_service_name,
            service_account_email= iam.sa_inspection_dispatcher.email,
            invoker_service_account_email= iam.sa_inspection_dispatcher_tasks.email,
            timeout_seconds= self.var.dispatcher_service_timeout_seconds,

            max_containers=1,
            max_cpu= 2,
            environment_variables=[
                EnvironmentVariable(name="INSPECTION_TOPIC", value=self.var.inspector_pubsub_topic),
                EnvironmentVariable(name="COMPUTE_REGION", value=self.var.compute_region),
                EnvironmentVariable(name="DATA_REGION_ID", value=self.var.data_region),
                EnvironmentVariable(name="PROJECT_ID", value=self.var.project),
                EnvironmentVariable(name="GCS_FLAGS_BUCKET", value=self.var.gcs_flags_bucket_name)
            ]
        ), opts= pulumi.ResourceOptions(parent= self, depends_on=[iam]), resource_name="cloud-run-inspection-dispatcher")
        return cloud_run_inspection_dispatcher
    
    def __setup_cloud_run_inspector(self, iam: IAM):
        cloud_run_inspector = CloudRunService(var= CloudRunArgs(
            project= self.var.project,
            region= self.var.compute_region,
            service_image= self.var.inspector_service_image,
            service_name= self.var.inspector_service_name,
            service_account_email= iam.sa_inspector.email,
            invoker_service_account_email= iam.sa_inspector_tasks.email,
            timeout_seconds= self.var.inspector_service_timeout_seconds,

            max_containers=1,
            max_cpu= 2,
            environment_variables=[
                EnvironmentVariable(name="REGION_ID", value=self.var.data_region),
                EnvironmentVariable(name="PROJECT_ID", value=self.var.project),
                EnvironmentVariable(name="DLP_INSPECTION_TEMPLATE_ID", value=self.var.dlp_inspection_template_id),
                EnvironmentVariable(name="MIN_LIKELIHOOD", value=self.var.dlp_min_likelihood),
                EnvironmentVariable(name="MAX_FINDINGS_PER_ITEM", value=self.var.dlp_max_findings_per_item),
                EnvironmentVariable(name="SAMPLING_METHOD", value=self.var.dlp_sampling_method),
                EnvironmentVariable(name="DLP_NOTIFICATION_TOPIC", value=self.var.tagger_topic_id),
                EnvironmentVariable(name="BQ_RESULTS_DATASET", value=self.var.bigquery_dataset_name),
                EnvironmentVariable(name="BQ_RESULTS_TABLE", value=self.var.standard_dlp_results_table_name),
                EnvironmentVariable(name="TABLE_SCAN_LIMITS_JSON_CONFIG", value=self.var.table_scan_limits_json_config),
                EnvironmentVariable(name="GCS_FLAGS_BUCKET", value=self.var.gcs_flags_bucket_name)
           ]
        ), opts= pulumi.ResourceOptions(parent= self, depends_on=[iam]), resource_name="cloud-run-inspector")
        return cloud_run_inspector
    
    def __setup_pubsub_inspection_dispatcher(self, inspection_dispatcher: CloudRunService, iam: IAM):
        pubsub_inspection_dispatcher = PubSub(var= PubSubArgs(
            project_id= self.var.project,
            subscription_endpoint=  inspection_dispatcher.service_endpoint,
            subscription_name= self.var.dispatcher_pubsub_sub,
            subscription_service_account= iam.sa_inspection_dispatcher_tasks.email,
            topic= self.var.dispatcher_pubsub_topic,
            topic_publishers_sa_emails= [ self.var.cloud_scheduler_account],
            subscription_ack_deadline_seconds= self.var.dispatcher_subscription_ack_deadline_seconds,
            subscription_message_retention_duration= self.var.dispatcher_subscription_message_retention_duration,
        ), opts= pulumi.ResourceOptions(parent= self, depends_on=[inspection_dispatcher]))

        return pubsub_inspection_dispatcher

    def __setup_pubsub_inspector(self, inspector: CloudRunService, iam: IAM):
        inspector = PubSub(var= PubSubArgs(
            project_id= self.var.project,
            subscription_endpoint=  inspector.service_endpoint,
            subscription_name= self.var.inspector_pubsub_sub,
            subscription_service_account= iam.sa_inspector_tasks.email,
            topic= self.var.inspector_pubsub_topic,
            topic_publishers_sa_emails= [ iam.sa_inspection_dispatcher.email],
            subscription_ack_deadline_seconds= self.var.inspector_subscription_ack_deadline_seconds,
            subscription_message_retention_duration= self.var.inspector_subscription_message_retention_duration,
        ), opts= pulumi.ResourceOptions(parent= self, depends_on=[inspector, iam]))

        return inspector