

import pulumi
from models.modules.iam_args import IAMArgs
from pulumi_gcp import serviceaccount, bigquery, projects, datacatalog
from pulumi.output import Output

class IAM(pulumi.ComponentResource):
    def __init__(self, var : IAMArgs, opts: None):
        super().__init__("custom:modules:IAM", "IAM", None, opts=opts)
        self.var = var
        self.child_opts = pulumi.ResourceOptions(parent=self, replace_on_changes= ["*"])
        self.__setup_locals()

        self.__deploy()

    def __deploy(self):
        var = self.var
        ############## Service Accounts ######################################
        sa_tagging_dispatcher = serviceaccount.Account(
        "sa_tagging_dispatcher",
        account_id=var.sa_tagging_dispatcher,
         display_name="Runtime SA for Tagging Dispatcher service",
        project=var.project,
        opts=self.child_opts
        )

        sa_tagger = serviceaccount.Account(
        "sa_tagger",
        account_id=var.sa_tagger,
         display_name="Runtime SA for Tagger service",
        project=var.project,
        opts=self.child_opts
        )

        sa_tagger_tasks = serviceaccount.Account(
        "sa_tagger_tasks",
        account_id=var.sa_tagger_tasks,
         display_name="To authorize PubSub Push requests to Tagger Service",
        project=var.project,
        opts=self.child_opts
        )

        sa_tagging_dispatcher_tasks = serviceaccount.Account(
                "sa_tagging_dispatcher_tasks",
                account_id=var.sa_tagging_dispatcher_tasks,
                display_name="To authorize PubSub Push requests to Tagging Dispatcher Service",
                project=var.project,
                opts=self.child_opts
                )
        
        #### Dispatcher Tasks Permissions ###
        sa_tagging_dispatcher_account_user_sa_dispatcher_tasks = serviceaccount.IAMMember(
        "sa_tagging_dispatcher_account_user_sa_dispatcher_tasks",
        service_account_id=sa_tagging_dispatcher.name,
        role="roles/iam.serviceAccountUser",
        member=sa_tagging_dispatcher_tasks.email.apply(lambda x: f"serviceAccount:{x}"),
        opts=self.child_opts
        )

        #### Dispatcher SA Permissions ###

        # Grant sa_dispatcher access to submit query jobs
        sa_tagging_dispatcher_bq_job_user = projects.IAMMember(
            "sa_tagging_dispatcher_bq_job_user",
            project=var.project,
            role="roles/bigquery.jobUser",
            member=sa_tagging_dispatcher.email.apply(lambda x: f"serviceAccount:{x}")  ,
            opts=self.child_opts
            )
        
        # tagging dispatcher needs to read data from dlp results table and views created inside the solution-managed dataset
        # e.g. listing tables to be tagged
        sa_tagging_dispatcher_bq_dataset_reader = bigquery.DatasetAccess(
        "sa_tagging_dispatcher_bq_dataset_reader",
        dataset_id=var.bq_results_dataset,
        role="roles/bigquery.dataViewer",
        user_by_email=sa_tagging_dispatcher.email,
        opts=self.child_opts
        )

        #### Tagger Tasks SA Permissions ###
        sa_tagger_account_user_sa_tagger_tasks = serviceaccount.IAMMember(
            "sa_tagger_account_user_sa_tagger_tasks",
            service_account_id=sa_tagger.name,
            role="roles/iam.serviceAccountUser",
            member=sa_tagger_tasks.email.apply(lambda x: f"serviceAccount:{x}") ,
            opts=self.child_opts)

        #### Tagger SA Permissions ###
        tagger_role = projects.IAMCustomRole(
        "tagger-role",
        project=var.project,
        role_id=var.tagger_role,
        title=var.tagger_role,
        description="Used to grant permissions to sa_tagger",
        permissions=[
            "bigquery.tables.setCategory",
            "datacatalog.taxonomies.get",
        ],
        opts=self.child_opts
        )
        
        sa_tagger_role = projects.IAMMember(
            "sa_tagger_role",
            project=var.project,
            role=tagger_role.name,
            member=sa_tagger.email.apply(lambda email: f"serviceAccount:{email}"),
            opts=self.child_opts
            )
        

        # tagger needs to read data from views created inside the solution-managed dataset
        # e.g. dlp results view
        sa_tagger_bq_dataset_reader = bigquery.DatasetAccess(
        "sa_tagger_bq_dataset_reader",
        dataset_id=var.bq_results_dataset,
        role="roles/bigquery.dataViewer",
        user_by_email=sa_tagger.email,
        opts=self.child_opts
        )

        # to submit query jobs
        sa_tagger_bq_job_user = projects.IAMMember(
            "sa_tagger_bq_job_user",
            project=var.project,
            role=f"roles/bigquery.jobUser",
            member=sa_tagger.email.apply(lambda email: f"serviceAccount:{email}"),
            opts=self.child_opts
            ) 

        ############## DLP Service Account ################################################

        # DLP SA must read BigQuery columns tagged by solution-managed taxonomies
        dlp_sa_binding = projects.IAMMember(
            "dlp_sa_binding",
            project=var.project,
            role="roles/datacatalog.categoryFineGrainedReader",
            member=f"serviceAccount:{var.dlp_service_account}",
            opts=self.child_opts
        )


        dlp_access_bq_dataset = bigquery.DatasetIamMember(
            "dlp_access_bq_dataset",
            dataset_id=var.bq_results_dataset,
            role="roles/bigquery.dataEditor",
            member=f"serviceAccount:{var.dlp_service_account}",
            opts=self.child_opts
        )

        # Grant permissions for every member in the iam_members_list
        #debug_policy_tag_readers = []
        def apply_members(members):
            count = 0
            for member in members:
                    count += 1 
                    reader = datacatalog.PolicyTagIamMember(
                        f"policy_tag_{member.get('policy_tag_name', 'NA')}_[{count}]iam_member",
                        policy_tag=member.get("policy_tag_name", "NA"),
                        role="roles/datacatalog.categoryFineGrainedReader",
                        member=member.get("iam_member", "NA"),
                        opts=self.child_opts
                    )
            #debug_policy_tag_readers.append(reader)

        self.__iam_members_list.apply(lambda members: apply_members(members))

        

        """
        self.register_outputs({
        }    "sa_tagging_dispatcher_email": sa_tagging_dispatcher.email,
            "sa_tagger_email": sa_tagger.email,
            "sa_tagging_dispatcher_tasks": sa_tagging_dispatcher_tasks.email,
            "sa_tagger_tasks_email": sa_tagger_tasks.email,
                    })
        """
        self.sa_tagging_dispatcher = sa_tagging_dispatcher
        self.sa_tagging_dispatcher_tasks = sa_tagging_dispatcher_tasks
        self.sa_tagger = sa_tagger
        self.sa_tagger_tasks = sa_tagger_tasks
        self.sa_tagging_dispatcher_email = sa_tagging_dispatcher.email
        self.sa_tagger_email = sa_tagger.email
        

    def __setup_locals(self):
        var = self.var
        
        self.__parent_tags_with_members_list = [
            parent_tag.apply(lambda parent_tag:               
            {
            "policy_tag_name": parent_tag.id,
            "iam_members": var.iam_mapping.get(parent_tag.domain, {}).get(parent_tag.display_name, ["IAM_MEMBERS_LOOKUP_FAILED"])
            })
            for parent_tag in var.taxonomy_parent_tags
        ]

        
        # flatten the iam_members list inside of parent_tags_with_members_list
        self.__iam_members_list = Output.all(tags = self.__parent_tags_with_members_list).apply(lambda args:[
            {
            "policy_tag_name": entry.get("policy_tag_name", "NA"),
            "iam_member": member
            }
            for entry in args["tags"]
            for member in entry.get("iam_members", [])
        ])