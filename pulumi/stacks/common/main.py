from typing import List
import pulumi
import pulumi_gcp as gcp
from models.modules.cloud_run_args import CloudRunArgs, EnvironmentVariable
from models.modules.cloud_scheduler_args import CloudSchedulerArgs
from models.modules.data_catalog_args import DataCatalogArgs
from models.modules.dlp_bigquery_args import DLPBigqueryArgs
from models.modules.iam_args import IAMArgs, TaxonomyParentTags
from models.stack.common_stack_args import CommonStackArgs
from models.modules.pubsub_args import PubSubArgs

from modules.bigquery.main import DLPBigQuery
from modules.cloud_logging import CloudLogging
from modules.cloud_scheduler import CloudScheduler
from modules.data_catalog import DataCatalog
from modules.pubsub import PubSub

from modules.dlp import DataLossPrevention
from modules.iam import IAM
from modules.cloud_run import CloudRunService

class CommonStack(pulumi.ComponentResource):
    def __init__(self, var: CommonStackArgs, resource_name, opts=None):
        super().__init__("custom:stack:CommonStack", resource_name, None, opts)
        self.child_opts = pulumi.ResourceOptions(parent=self)

        self.var = var
        self.__setup_locals()
        

    def deploy(self):
        self.__enable_apis()
        
        catalogs = self.__setup_data_catalog()
        self.__setup_taxonomies(catalogs)

        self.logging = self.__setup_cloud_logging()

        big_query = self.__setup_bigquery(logging= self.logging)

        self.__setup_dlp()


        iam = self.__setup_iam()

        # cehck params      
        cloud_run_tagging_dispatcher = self.__setup_cloud_run_tagging_dispatcher(dispatcher_service_accoun_email=iam.sa_tagging_dispatcher.email,
                                 sa_tagging_dispatcher_tasks_email=iam.sa_tagging_dispatcher_tasks.email,
                                    pubsub_tagger_topic_name=self.var.tagger_pubsub_topic,
                                    logging_table=self.var.log_sink_name)
        

        pub_sub_tagging_dispatcher = self.__setup_tagging_distpatcher(iam = iam, tagging_dispatcher = cloud_run_tagging_dispatcher)

        pub_sub_tagging_dispatcher.topic_id.apply(lambda topic_id: 
                                                  self.__setup_cloud_scheduler(depends_on_resource=self.__enable_appengine, target_uri= topic_id))
        

        run_tagger = self.__setup_cloud_run_tagger(sa_tagger_email=iam.sa_tagger.email, sa_tagger_tasks_email=iam.sa_tagger_tasks.email,
                                      big_query=big_query)
        

        self.__setup_tagger(iam=iam, tagger_service=run_tagger)
        
    def __setup_locals(self):
        var = self.var
        
        # Get distinct project and domains
        self.__project_and_domains = list({"project" :entry.project, "domain" : entry.domain} for entry in var.domain_mapping)

        # Filter projects with configured domains
        self.__project_and_domains_filtered = [entry for entry in self.__project_and_domains if entry.get("domain", "") != ""]

        # Get distinct datasets and domains
        self.__datasets_and_domains = list({{ "project": entry.project, "name": dataset.name, "domain" :dataset.domain} for entry in var.domain_mapping for dataset in entry.datasets})

        # Filter datasets with configured domains
        self.__datasets_and_domains_filtered = [entry for entry in self.__datasets_and_domains if entry[2] != ""]

        # Get distinct project domains
        self.__project_domains = list({entry.get("domain", "") for entry in self.__project_and_domains_filtered})

        # Get distinct dataset domains
        self.__dataset_domains = list({entry[2] for entry in self.__datasets_and_domains_filtered})

        # Concatenate project and dataset domains and filter out empty strings
        self.__domains = [domain for domain in self.__project_domains + self.__dataset_domains if domain != ""]

        # Create comma-separated string of created taxonomies
        self.__created_taxonomies = ",".join([taxonomy['name'] for taxonomy in var.created_taxonomy])

        # Create auto DLP results latest view
        self.__auto_dlp_results_latest_view = f"{var.auto_dlp_results_table_name}_latest_v1"

    def __setup_taxonomies(self, catalogs: List[DataCatalog]):
        var = self.var
       
        # Flatten created policy tags
        
        self.__created_policy_tags = list(
                    pulumi.Output.all(tag.id, tag.description).apply(lambda args:
                                    { "id" : args[0],
                                        "domain":  args[1].split("|")[0].strip(),
                                        "info_type" : args[1].split("|")[1].strip() }
                    )
                     for catalog in catalogs for tag in catalog.children_tags)
      
        # Flatten created parent tags
        

        self.__created_parent_tags = list(
                    pulumi.Output.all(tag.id, tag.description, tag.display_name).apply(lambda args:
                                    { "id" : args[0],
                                        "domain":  args[1].split("|")[0].strip(),
                                        "display_name" : args[2].strip()}
                    )
                     for catalog in catalogs for tag in catalog.parent_tags)

    def __enable_apis(self):
        prefix = self.var.project + "-"
        var = self.var
        # Enable the Service Usage API
        service_name = "serviceusage.googleapis.com"
        self.__enable_service_usage_api = gcp.projects.Service(prefix+"enable_service_usage_api",
                                        project=var.project,
                                        service=service_name,
                                        disable_on_destroy=False)

        # Enable Cloud Scheduler API
        service_name = "appengine.googleapis.com"
        self.__enable_appengine = gcp.projects.Service(prefix+"enable_appengine",
                                    project=var.project,
                                        service=service_name,
                                        disable_on_destroy=False,
                                        disable_dependent_services=True)

        # Enalbe Cloud Build API
        service_name = "cloudbuild.googleapis.com"
        self.__enable_cloudbuild = gcp.projects.Service(prefix+"enable_cloudbuild",
                                    project=var.project,
                                        service=service_name,
                                        disable_on_destroy=False)

        # Enable Cloud Run API
        service_name = "run.googleapis.com"
        self.__run_api = gcp.projects.Service(prefix+"run_api",
                                    project=var.project,
                                        service=service_name,
                                        disable_on_destroy=False)

    def __setup_data_catalog(self) -> List[DataCatalog]:
        var = self.var
        catalogs = []
        for domain in self.__domains:
            data_catalog = DataCatalog(var= DataCatalogArgs(
                project=var.project,
                region= var.data_region,
                domain=domain,
                classification_taxonomy=var.classification_taxonomy,
                data_catalog_taxonomy_activated_policy_types=var.data_catalog_taxonomy_activated_policy_types,
             ), opts=self.child_opts)
            catalogs.append(data_catalog)
        
        return catalogs

    def __setup_bigquery(self, logging: CloudLogging):
        var = self.var
        self.bigquery = DLPBigQuery(var = DLPBigqueryArgs(
            project= var.project,
            region= var.compute_region,
            dataset= var.bigquery_dataset_name,
            logging_sink_sa=logging.service_account,
            created_parent_tags= self.__created_parent_tags,
            dataset_domain_mapping= self.__datasets_and_domains_filtered,
            created_policy_tags= self.__created_policy_tags,
            projects_domain_mapping= self.__project_and_domains_filtered,
            standard_dlp_results_table_name= var.standard_dlp_results_table_name,
        ), resource_name="bigquery" ,opts= pulumi.ResourceOptions(parent=self, depends_on=[logging]))
        return self.bigquery    

    def __setup_cloud_logging(self):
        var = self.var
        logging = CloudLogging(results_dataset_id=var.bigquery_dataset_name,
                                project_id=var.project,
                                log_sink_name=var.log_sink_name, opts=self.child_opts)
        return logging
    
    def __setup_dlp(self):
        var = self.var
        self.dlp = DataLossPrevention(var.project, var.compute_region,
                                var.classification_taxonomy,
                                opts=self.child_opts)
        return self.dlp
        
    
    def __setup_cloud_scheduler(self, depends_on_resource, target_uri: str):
        var = self.var
       
        cloud_scheduler = CloudScheduler(var= CloudSchedulerArgs(
                project=var.project,
                region= var.compute_region,
                scheduler_name=var.scheduler_name,
                target_uri=target_uri,
                tables_include_list=var.tables_include_list,
                datasets_include_list=var.datasets_include_list,
                projects_include_list=var.projects_include_list,
                datasets_exclude_list=var.datasets_exclude_list,
                tables_exclude_list=var.tables_exclude_list,
                cron_expression=var.cron_expression,
                depends_on= [depends_on_resource]
            ), opts= self.child_opts)

    
    def __setup_iam(self):
        var = self.var
        # Create IAM bindings for the service account
        iam = IAM(var=IAMArgs(
            project=var.project,
            sa_tagger=var.sa_tagger,
            sa_tagger_tasks=var.sa_tagger_tasks,
            taxonomy_parent_tags= [tag.apply(lambda x: TaxonomyParentTags(**x)) for tag in self.__created_parent_tags],
            iam_mapping=var.iam_mapping,
            dlp_service_account=var.dlp_service_account,
            tagger_role=var.tagger_role,
            sa_tagging_dispatcher=var.sa_tagging_dispatcher,
            sa_tagging_dispatcher_tasks=var.sa_tagging_dispatcher_tasks, 
            bq_results_dataset=self.bigquery.result_ds.dataset_id,
        ), opts= pulumi.ResourceOptions(parent=self, depends_on=[self.dlp]))
        self.iam = iam
        return iam
    
    def __setup_cloud_run_tagging_dispatcher(self, dispatcher_service_accoun_email: pulumi.Output[str],
                           sa_tagging_dispatcher_tasks_email: pulumi.Output[str],
                           pubsub_tagger_topic_name:str,
                           logging_table : str
                           ):
        var = self.var
        cloud_run = CloudRunService(var=CloudRunArgs(
            project=var.project,
            region=var.compute_region,
            service_image=var.dispatcher_service_image,
            service_name=var.dispatcher_service_name,
            service_account_email=dispatcher_service_accoun_email,
            invoker_service_account_email=sa_tagging_dispatcher_tasks_email,
            timeout_seconds= var.dispatcher_service_timeout_seconds,
            max_containers=1,
            max_cpu=2,
            environment_variables=[           
                EnvironmentVariable(name="TAGGER_TOPIC", value=pubsub_tagger_topic_name),
                EnvironmentVariable(name="COMPUTE_REGION_ID", value=var.compute_region),
                EnvironmentVariable(name="DATA_REGION_ID", value=var.data_region),
                EnvironmentVariable(name="PROJECT_ID", value=var.project),
                EnvironmentVariable(name="GCS_FLAGS_BUCKET", value=var.gcs_flags_bucket_name),
                EnvironmentVariable(name="SOLUTION_DATASET", value=var.bigquery_dataset_name),
                EnvironmentVariable(name="DLP_TABLE_STANDARD", value=var.standard_dlp_results_table_name),
                EnvironmentVariable(name="DLP_TABLE_AUTO", value=self.__auto_dlp_results_latest_view),
                EnvironmentVariable(name="IS_AUTO_DLP_MODE", value=str(var.is_auto_dlp_mode)),
                EnvironmentVariable(name="LOGGING_TABLE", value=logging_table)]      
        ), resource_name="cloud-run-tagging-dispatcher", opts=pulumi.ResourceOptions(parent=self, depends_on=[self.iam, self.bigquery]))

        return cloud_run
    
    def __setup_cloud_run_tagger(self, sa_tagger_email: pulumi.Output[str],
                           sa_tagger_tasks_email: pulumi.Output[str],
                           big_query : DLPBigQuery):
        var = self.var
        cloud_run = CloudRunService(var=CloudRunArgs(
            project=var.project,
            region=var.compute_region,
            service_image=var.tagger_service_image,
            service_name=var.tagger_service_name,
            service_account_email=sa_tagger_email,
            invoker_service_account_email=sa_tagger_tasks_email,
            timeout_seconds= var.tagger_service_timeout_seconds,
            max_containers=1,
            max_cpu=2,
            environment_variables=[
                EnvironmentVariable(name="IS_DRY_RUN", value=var.is_dry_run),
                EnvironmentVariable(name="TAXONOMIES", value=self.__created_taxonomies),
                EnvironmentVariable(name="REGION_ID", value=var.compute_region),
                EnvironmentVariable(name="PROJECT_ID", value=var.project),
                EnvironmentVariable(name="GCS_FLAGS_BUCKET", value=var.gcs_flags_bucket_name),
                EnvironmentVariable(name="DLP_DATASET", value=var.bigquery_dataset_name),
                EnvironmentVariable(name="DLP_TABLE_STANDARD", value=var.standard_dlp_results_table_name),
                EnvironmentVariable(name="DLP_TABLE_AUTO", value=self.__auto_dlp_results_latest_view),
                EnvironmentVariable(name="VIEW_INFOTYPE_POLICYTAGS_MAP", value=big_query.config_view_infotypes_policytags_map),
                EnvironmentVariable(name="VIEW_DATASET_DOMAIN_MAP", value=big_query.config_view_dataset_domain_map),
                EnvironmentVariable(name="VIEW_PROJECT_DOMAIN_MAP", value=big_query.config_view_project_domain_map),
                EnvironmentVariable(name="PROMOTE_MIXED_TYPES", value=str(var.promote_mixed_info_types)),
                EnvironmentVariable(name="IS_AUTO_DLP_MODE", value=str(var.is_auto_dlp_mode))
            ]
        ), resource_name="cloud-run-tagger", opts= pulumi.ResourceOptions(parent=self, depends_on=[self.iam ,big_query]))
        return cloud_run
    
    def __setup_tagging_distpatcher(self, iam: IAM, tagging_dispatcher: CloudRunService):
        pub_sub_tagging_dispatcher = PubSub(var=PubSubArgs(
            project_id=self.var.project,
            subscription_endpoint=tagging_dispatcher.service_endpoint,
            subscription_name=self.var.dispatcher_pubsub_sub,
            subscription_service_account=iam.sa_tagging_dispatcher_tasks.email,
            topic=self.var.dispatcher_pubsub_topic,
            topic_publishers_sa_emails=[self.var.cloud_scheduler_account],
            subscription_ack_deadline_seconds=self.var.dispatcher_subscription_ack_deadline_seconds,
            subscription_message_retention_duration= self.var.dispatcher_subscription_message_retention_duration
        ),
        opts= pulumi.ResourceOptions(parent=self, depends_on=[iam, tagging_dispatcher]))
        return pub_sub_tagging_dispatcher
    
    def __setup_tagger(self, iam: IAM, tagger_service: CloudRunService):
        pubsub_tagger = PubSub(var=PubSubArgs(
            project_id=self.var.project,
            subscription_endpoint=tagger_service.service_endpoint,
            subscription_name=self.var.tagger_pubsub_sub,
            subscription_service_account=iam.sa_tagger_tasks.email,
            topic=self.var.tagger_pubsub_topic,
            topic_publishers_sa_emails=[iam.sa_tagging_dispatcher.email, self.var.dlp_service_account],
            subscription_ack_deadline_seconds=self.var.tagger_subscription_ack_deadline_seconds,
            subscription_message_retention_duration= self.var.tagger_subscription_message_retention_duration
        ),opts= pulumi.ResourceOptions(parent=self, depends_on=[iam, tagger_service]))
        self.pubsub_tagger = pubsub_tagger