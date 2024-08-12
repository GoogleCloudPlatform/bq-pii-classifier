import json
from models.modules.clasification_taxonomy_args import ClasificationTaxonomyArgs
from models.stack.common_stack_args import CommonStackArgs
from models.stack.domain_mapping import DomainMapping
from models.stack.inspection_stack_args import InspectionStackArgs
from modules.gcs import GoogleCloudStorage
from stacks.common.main import CommonStack
from config import variables as var
from stacks.inspection.main import InspectionStack
import pulumi


class DataLakeDLP(pulumi.ComponentResource):
    def __init__(self, resource_name: str, opts: pulumi.ResourceOptions = None):
        super().__init__("custom:stack:DataLakeDLP", resource_name, None, opts)
        self._child_opts = pulumi.ResourceOptions(parent=self)

    def deploy(self):
        
        gcs = GoogleCloudStorage(
            project_id=var.project_id,
            bucket_name=f"{var.project_id}-{var.gcs_flags_bucket_name}",
            region=var.compute_region,
            gcs_flags_bucket_admins = [] if var.is_auto_dlp_mode else [],
            opts=self._child_opts
        ) 

        common_stack = CommonStack(var= CommonStackArgs(
            classification_taxonomy=[ClasificationTaxonomyArgs(**t) for t in var.classification_taxonomy],
            cloud_scheduler_account=var.cloud_scheduler_account,
            cron_expression=var.tagging_cron_expression,
            datasets_exclude_list=var.datasets_exclude_list,
            datasets_include_list=var.datasets_include_list,
            dispatcher_service_image=var.tagging_dispatcher_service_image,
            dlp_service_account= var.dlp_service_account,
            domain_mapping=[DomainMapping(**d) for d in var.domain_mapping],
            iam_mapping=var.iam_mapping,
            is_dry_run= var.is_dry_run,
            project=var.project_id,
            projects_include_list=var.projects_include_list,
            compute_region=var.compute_region,
            data_region=var.data_region,
            tables_exclude_list=var.tables_exclude_list,
            tables_include_list=var.tables_include_list,
            tagger_service_image=var.tagger_service_image,
            bigquery_dataset_name= var.bigquery_dataset_name,
            dispatcher_pubsub_sub= var.tagging_dispatcher_pubsub_sub,
            dispatcher_pubsub_topic= var.tagging_dispatcher_pubsub_topic,
            dispatcher_service_name= var.tagging_dispatcher_service_name,
            log_sink_name= var.log_sink_name,
            sa_tagger= var.sa_tagger,
            sa_tagger_tasks= var.sa_tagger_tasks,
            scheduler_name= var.tagging_scheduler_name,
            tagger_pubsub_sub= var.tagger_pubsub_sub,
            tagger_pubsub_topic= var.tagger_pubsub_topic,
            tagger_role= var.tagger_role,
            tagger_service_name= var.tagger_service_name,
            is_auto_dlp_mode= var.is_auto_dlp_mode,
            auto_dlp_results_table_name= var.auto_dlp_results_table_name,
            standard_dlp_results_table_name= var.standard_dlp_results_table_name,
            sa_tagging_dispatcher= var.sa_tagging_dispatcher,
            sa_tagging_dispatcher_tasks= var.sa_tagging_dispatcher_tasks,
            data_catalog_taxonomy_activated_policy_types= var.data_catalog_taxonomy_activated_policy_types,
            gcs_flags_bucket_name= var.gcs_flags_bucket_name,

            dispatcher_service_timeout_seconds= var.dispatcher_service_timeout_seconds,
            dispatcher_subscription_ack_deadline_seconds= var.dispatcher_subscription_ack_deadline_seconds,
            dispatcher_subscription_message_retention_duration= var.dispatcher_subscription_message_retention_duration,
            tagger_service_timeout_seconds= var.tagger_service_timeout_seconds,
            tagger_subscription_ack_deadline_seconds= var.tagger_subscription_ack_deadline_seconds,
            tagger_subscription_message_retention_duration= var.tagger_subscription_message_retention_duration,
            promote_mixed_info_types= var.promote_mixed_info_types

        ), resource_name="common-stack", opts=pulumi.ResourceOptions(parent=self, depends_on=[gcs]))
        
        common_stack.deploy()

        common_gcs_admins = [
            common_stack.iam.sa_tagging_dispatcher_email.apply(lambda e: f"serviceAccount:{e}"),
            common_stack.iam.sa_tagger_email.apply(lambda e: f"serviceAccount:{e}")
        ]

        if not var.is_auto_dlp_mode:
            inspection_stack = InspectionStack(var= InspectionStackArgs(
                bigquery_dataset_name= common_stack.bigquery.result_ds.dataset_id,
                cloud_scheduler_account=var.cloud_scheduler_account,
                cron_expression= var.inspection_cron_expression,
                datasets_exclude_list= var.datasets_exclude_list,
                datasets_include_list= var.datasets_include_list,
                dispatcher_service_image= var.inspection_dispatcher_service_image,
                dlp_inspection_template_id=  common_stack.dlp.inspection_template.id,
                inspector_service_image= var.inspector_service_image,

                project= var.project_id,
                projects_include_list= var.projects_include_list,
                compute_region= var.compute_region,
                data_region= var.data_region,
                table_scan_limits_json_config= json.dumps(var.table_scan_limits_json_config),
                tables_exclude_list= var.tables_exclude_list,
                tables_include_list= var.tables_include_list,
                tagger_topic_id= common_stack.pubsub_tagger.topic_id,
                dispatcher_pubsub_sub= var.inspection_dispatcher_pubsub_sub,
                dispatcher_pubsub_topic = var.inspection_dispatcher_pubsub_topic,
                dispatcher_service_name = var.inspection_dispatcher_service_name,
                inspector_pubsub_sub = var.inspector_pubsub_sub,
                inspector_pubsub_topic = var.inspector_pubsub_topic,
                inspector_service_name = var.inspector_service_name,
                sa_inspector = var.sa_inspector,
                sa_inspector_tasks = var.sa_inspector_tasks,
                scheduler_name = var.inspection_scheduler_name,
                standard_dlp_results_table_name = var.standard_dlp_results_table_name,
                sa_inspection_dispatcher = var.sa_inspection_dispatcher,
                sa_inspection_dispatcher_tasks = var.sa_inspection_dispatcher_tasks,
                dlp_max_findings_per_item = var.dlp_max_findings_per_item,
                dlp_min_likelihood = var.dlp_min_likelihood,
                dlp_sampling_method = var.dlp_sampling_method,
                gcs_flags_bucket_name = gcs.gcs_flags_bucket.name,
                dispatcher_service_timeout_seconds = var.dispatcher_service_timeout_seconds,
                dispatcher_subscription_ack_deadline_seconds= var.dispatcher_subscription_ack_deadline_seconds,
                dispatcher_subscription_message_retention_duration= var.dispatcher_subscription_message_retention_duration,
                inspector_service_timeout_seconds= var.inspector_service_timeout_seconds,
                inspector_subscription_ack_deadline_seconds= var.inspector_subscription_ack_deadline_seconds,
                inspector_subscription_message_retention_duration= var.inspector_subscription_message_retention_duration,

            ), resource_name="inspection-stack",opts=pulumi.ResourceOptions(parent=self, depends_on= [gcs, common_stack]))

            inspection_stack.deploy()
            
            inspection_gcs_admins = [
            inspection_stack.iam.sa_inspection_dispatcher.email.apply(lambda e: f"serviceAccount:{e}"),
            inspection_stack.iam.sa_inspector.email.apply(lambda e: f"serviceAccount:{e}")
            ]
   

        gcs_admins = common_gcs_admins
        if not var.is_auto_dlp_mode:            
            gcs_admins = gcs_admins + inspection_gcs_admins

        pulumi.Output.all(sa =gcs_admins).apply(lambda args: gcs.setup_bucket_iam_admins(args["sa"]))