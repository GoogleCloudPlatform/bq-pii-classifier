import pulumi
from pulumi_gcp import bigquery
from models.modules.dlp_bigquery_args import DLPBigqueryArgs
from config.utils import replace_template_variables, read_file


class DLPBigQuery(pulumi.ComponentResource):
    def __init__(self,var: DLPBigqueryArgs, resource_name, opts: None):
        super().__init__("custom:modules:DLPBigQuery", resource_name, opts=opts)
        self.child_opts = pulumi.ResourceOptions(parent=self)

        self.var :DLPBigqueryArgs  = var

        self.__deploy()

    def __deploy(self):
        var = self.var
        
        self.result_ds = self.__create_datasets(var.project, var.region, var.dataset, var.logging_sink_sa)
        
        logging_table, standard_dlp_results_table = self.__create_tables(self.result_ds.dataset_id)
        
        config_view_infotypes_policytags_map, \
        config_view_project_domain_map, \
        config_view_dataset_domain_map  = self.__create_config_views(self.result_ds.dataset_id)

        pulumi.Output.all(logging_table.table_id, config_view_infotypes_policytags_map.table_id, self.result_ds.dataset_id).apply(lambda table_ids:
             self.__create_monitoring_views(table_ids[2], table_ids[0], table_ids[1]) )
        
        

        self.register_outputs({
            "results_dataset_id": self.result_ds.dataset_id,
            "results_table_standard_dlp": standard_dlp_results_table.table_id,
            "logging_table": logging_table.table_id,
            "config_view_infotypes_policytags_map": config_view_infotypes_policytags_map.table_id,
            "config_view_project_domain_map": config_view_project_domain_map.table_id,
            "config_view_dataset_domain_map" : config_view_dataset_domain_map.table_id
        })
        
        self.config_view_infotypes_policytags_map = config_view_infotypes_policytags_map.table_id
        self.config_view_project_domain_map = config_view_project_domain_map.table_id
        self.config_view_dataset_domain_map = config_view_dataset_domain_map.table_id

    def __create_datasets(self, project: str, region: str, dataset: str, logging_sink_sa: pulumi.Output[str]):
        # Create BigQuery dataset
        results_dataset = bigquery.Dataset("results_dataset",
            project=project,
            location=region,
            dataset_id=dataset,
            description="To store DLP results from BQ Security Classifier app",
            opts=self.child_opts
        )

        # Grant access to logging sink
        logging_sink_access = bigquery.DatasetIamMember("logging_sink_access",
            dataset_id=results_dataset.dataset_id,
            role="roles/bigquery.dataEditor",
            member=logging_sink_sa,
            opts=self.child_opts
        )
        return results_dataset

    def __create_tables(self, standard_dlp_results_table_name: str):
        ##### Tables #######################################################
        project = self.var.project
        dataset_id = self.result_ds.dataset_id

        # Create standard_dlp_results_table
        standard_dlp_results_table = bigquery.Table("standard_dlp_results_table",
            project=project,
            dataset_id= dataset_id,
            table_id=standard_dlp_results_table_name,
            time_partitioning={
            "type": "DAY"
            },
            clusterings=["job_name"],
            #clustering=["job_name"],
            schema=read_file("./modules/bigquery/schema/standard_dlp_results.json"),
            deletion_protection=False,
            opts=self.child_opts
        )

        # Create logging_table
        logging_table = bigquery.Table("logging_table",
            project=project,
            dataset_id=dataset_id,
            table_id="run_googleapis_com_stdout",
            time_partitioning={
            "type": "DAY"
            },
            schema=read_file("./modules/bigquery/schema/run_googleapis_com_stdout.json"),
            deletion_protection=True,
            opts=self.child_opts
        )
        return logging_table, standard_dlp_results_table
    
    def __create_monitoring_views(self, results_dataset_id: str, logging_table_id: str,
                                  config_view_infotypes_policytags_id : str):
        ### Monitoring Views ##################################################
        project = self.var.project
        dataset = self.var.dataset
      

        # Create logging_view_tag_history resource
        logging_view_tag_history = bigquery.Table("logging_view_tag_history",
            dataset_id= results_dataset_id,
            table_id="v_log_tag_history",
            deletion_protection=False,
            view= bigquery.TableViewArgs(
                use_legacy_sql=False,
                query=replace_template_variables({
                    "project": project,
                    "dataset": dataset,
                    "logging_table": logging_table_id
                }, file_path= "./modules/bigquery/views/v_log_tag_history.tpl")
            ),
            opts=self.child_opts
        )
        
        
        # Create logging_view_steps resource
        logging_view_steps = bigquery.Table("logging_view_steps",
            dataset_id= results_dataset_id,
            table_id="v_steps",
            deletion_protection=False,
            view= bigquery.TableViewArgs(
                use_legacy_sql=False,
                query=replace_template_variables({
                    "project": project,
                    "dataset": dataset,
                    "logging_table": logging_table_id
                }, file_path= "./modules/bigquery/views/v_steps.tpl")
            ),
            opts=self.child_opts
        )
        
        # Create view_service_calls resource
        view_service_calls = bigquery.Table("view_service_calls",
            dataset_id= results_dataset_id,
            table_id="v_service_calls",
            deletion_protection=False,
            view= bigquery.TableViewArgs(
                use_legacy_sql=False,
                query=logging_view_steps.table_id.apply( lambda table_id : replace_template_variables({
                    "project": project,
                    "dataset": dataset,
                    "logging_view_steps": table_id
                }, file_path= "./modules/bigquery/views/v_service_calls.tpl")
                )
        ) , opts = pulumi.ResourceOptions(parent=self, depends_on=[logging_view_steps]) )

        # Create logging_view_broken_steps resource

        logging_view_broken_steps = bigquery.Table("logging_view_broken_steps",
            dataset_id=results_dataset_id,
            table_id="v_broken_steps",
            deletion_protection=False,
            view=bigquery.TableViewArgs(
                use_legacy_sql=False,
                query=(view_service_calls.table_id.apply( lambda table_id: replace_template_variables({
                    "project": project,
                    "dataset": dataset,
                    "v_service_calls": table_id,
                    "logging_table": logging_table_id
                }, file_path="./modules/bigquery/views/v_broken_steps.tpl"))
            )),
            opts= pulumi.ResourceOptions(parent=self, depends_on=[view_service_calls])
        )

        # Create view_tagging_actions resource
        view_tagging_actions = bigquery.Table("view_tagging_actions",
            dataset_id=results_dataset_id,
            table_id="v_tagging_actions",
            deletion_protection=False,
            view=bigquery.TableViewArgs(
            use_legacy_sql=False,
            query= logging_view_tag_history.table_id.apply(lambda table_id: 
                replace_template_variables({
                "project": project,
                "dataset": dataset,
                "v_log_tag_history": table_id,
                "v_config_infotypes_policytags_map": config_view_infotypes_policytags_id
            }, file_path="./modules/bigquery/views/v_tagging_actions.tpl"))
            ),
            opts=pulumi.ResourceOptions(parent=self, depends_on=[logging_view_tag_history])
        )
        
        view_run_summary = bigquery.Table("view_run_summary",
            dataset_id= results_dataset_id,
            table_id="v_run_summary",
            deletion_protection=False,
            view=bigquery.TableViewArgs(
            use_legacy_sql=False,
            query= pulumi.Output.all(view_service_calls.table_id, logging_view_broken_steps.table_id).apply(
                lambda table_ids: replace_template_variables({
                "project": project,
                "dataset": dataset,
                "v_service_calls": table_ids[0],
                "v_broken_steps": table_ids[1],
            }, file_path="./modules/bigquery/views/v_run_summary.tpl")
            ) 
            ),
            opts= pulumi.ResourceOptions(parent=self, depends_on=[view_service_calls, logging_view_broken_steps])
        )


        view_run_summary_counts = bigquery.Table("view_run_summary_counts",
            dataset_id=results_dataset_id,
            table_id="v_run_summary_counts",
            deletion_protection=False,
            view=bigquery.TableViewArgs(
            use_legacy_sql=False,
            query= view_run_summary.table_id.apply(lambda table_id:
            replace_template_variables({
                "project": project,
                "dataset": dataset,
                "v_run_summary": table_id
            }, file_path="./modules/bigquery/views/v_run_summary_counts.tpl"))
            ),
            opts= pulumi.ResourceOptions(parent=self, depends_on=[view_run_summary])
        )
        view_errors_non_retryable = bigquery.Table("view_errors_non_retryable",
            dataset_id=results_dataset_id,
            table_id="v_errors_non_retryable",
            deletion_protection=False,
            view=bigquery.TableViewArgs(
            use_legacy_sql=False,
            query=replace_template_variables({
                "project": project,
                "dataset": dataset,
                "logging_table": logging_table_id
            }, file_path="./modules/bigquery/views/v_errors_non_retryable.tpl")
            ),
            opts=self.child_opts
        )

        view_tracking_id_map = bigquery.Table("view_tracking_id_map",
            dataset_id=results_dataset_id,
            table_id="v_tracking_id_to_table_map",
            deletion_protection=False,
            view=bigquery.TableViewArgs(
            use_legacy_sql=False,
            query=replace_template_variables({
                "project": project,
                "dataset": dataset,
                "logging_table": logging_table_id
            }, file_path="./modules/bigquery/views/v_tracking_id_to_table_map.tpl")
            ),
            opts=self.child_opts
        )


    def __create_config_views(self, results_dataset_id: str):
        infotypes_policytags_map_select_statements = pulumi.Output.all(tags= self.var.created_policy_tags).apply(lambda args:
            [
            f"SELECT '{entry.get('domain', 'NA')}' AS domain, '{entry.get('info_type', 'NA')}' AS info_type, '{entry.get('policy_tag_id', 'NA')}' AS policy_tag" 
            for entry in args["tags"]])

        project_domain_map_select_statements = [
            f"SELECT '{entry.get('project')}' AS project, '{entry.get('domain')}' AS domain"
            for entry in self.var.projects_domain_mapping]

        dataset_domain_map_select_statements =  (
            ["SELECT '' AS project, '' AS dataset, '' AS domain"]
            if len(self.var.dataset_domain_mapping) == 0
            else [
                f"SELECT '{entry.get('project')}' AS project, '{entry.get('dataset')}' AS dataset, '{entry.get('domain')}' AS domain"
                for entry in self.var.dataset_domain_mapping
            ]
        )
        
        config_view_infotypes_policytags_map = bigquery.Table("config_view_infotypes_policytags_map",
            dataset_id=results_dataset_id,
            table_id="v_config_infotypes_policytags_map",
            deletion_protection=False,
            view=bigquery.TableViewArgs(
                use_legacy_sql=False,
                query=infotypes_policytags_map_select_statements.apply(lambda args: " UNION ALL \n".join(args)),
            ),
            opts=self.child_opts
        )

        config_view_project_domain_map = bigquery.Table("config_view_project_domain_map",
            dataset_id=results_dataset_id,
            table_id="v_config_projects_domains_map",
            deletion_protection=False,
            view=bigquery.TableViewArgs(
                use_legacy_sql=False,
                query=" UNION ALL \n".join(project_domain_map_select_statements),
            ),
            opts=self.child_opts
        )

        config_view_dataset_domain_map = bigquery.Table("config_view_dataset_domain_map",
            dataset_id=results_dataset_id,
            table_id="v_config_datasets_domains_map",
            deletion_protection=False,
            view=bigquery.TableViewArgs(
                use_legacy_sql=False,
                query=" UNION ALL \n".join(dataset_domain_map_select_statements),
            ),
            opts=self.child_opts
        )
    
        return config_view_infotypes_policytags_map,config_view_project_domain_map,config_view_dataset_domain_map