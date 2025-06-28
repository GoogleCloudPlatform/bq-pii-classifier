import pulumi
from pulumi_gcp import serviceaccount,  projects
from models.stack.inspection_stack_args import InspectionStackArgs

class IAM(pulumi.Resource):
    def __init__(self, resource_name:str,  var: InspectionStackArgs, opts: pulumi.ResourceOptions = None):
        super().__init__("custom:module:inspection:IAM", resource_name, None, opts)
        self.var = var
        self.child_opts = pulumi.ResourceOptions(parent=self)
        self.__deploy()

    def __deploy(self):

        self.sa_inspection_dispatcher = serviceaccount.Account(
            "sa_inspection_dispatcher",
            project=self.var.project,
            account_id=self.var.sa_inspection_dispatcher,
            description="Runtime SA for Inspection Dispatcher service",
            opts=self.child_opts
        )

        self.sa_inspector = serviceaccount.Account(
            "sa_inspector",
            project=self.var.project,
            account_id=self.var.sa_inspector,
            description="Runtime SA for Inspector service",
            opts=self.child_opts
        )

        self.sa_inspection_dispatcher_tasks = serviceaccount.Account(
            "sa_inspection_dispatcher_tasks",
            project=self.var.project,
            account_id=self.var.sa_inspection_dispatcher_tasks,
            description="To authorize PubSub Push requests to Inspection Dispatcher Service",
            opts=self.child_opts
        )

        self.sa_inspector_tasks = serviceaccount.Account(
            "sa_inspector_tasks",
            project=self.var.project,
            account_id=self.var.sa_inspector_tasks,
            description="To authorize PubSub Push requests to Inspector Service",
            opts=self.child_opts
        )
        ############## Service Accounts Access ################################

        # Use google_project_iam_member because it's Non-authoritative.
        # It Updates the IAM policy to grant a role to a new member.
        # Other members for the role for the project are preserved.


        #### Dispatcher Tasks Permissions ###

        self.sa_inspection_dispatcher_account_user_sa_dispatcher_tasks = serviceaccount.IAMMember(
            "sa_inspection_dispatcher_account_user_sa_dispatcher_tasks",
            service_account_id= self.sa_inspection_dispatcher_tasks.name,
            role="roles/iam.serviceAccountUser",
            member= self.sa_inspection_dispatcher_tasks.email.apply(lambda e: f"serviceAccount:{e}"),
            opts=self.child_opts
        )

        #### Dispatcher SA Permissions ###
        # Grant sa_dispatcher access to submit query jobs
        self.sa_inspection_dispatcher_bq_job_user = projects.IAMMember(
            "sa_inspection_dispatcher_bq_job_user",
            project=self.var.project,
            role="roles/bigquery.jobUser",
            member= self.sa_inspection_dispatcher.email.apply(lambda e: f"serviceAccount:{e}"),
            opts=self.child_opts
        )

        #### Inspector Tasks SA Permissions ###
        self.sa_inspector_account_user_sa_inspector_tasks = serviceaccount.IAMMember(
            "sa_inspector_account_user_sa_inspector_tasks",
            service_account_id=self.sa_inspector.name,
            role="roles/iam.serviceAccountUser",
            member= self.sa_inspector_tasks.email.apply(lambda e: f"serviceAccount:{e}"),
            opts=self.child_opts
        )

        #### Inspector SA Permissions ###
        self.sa_inspector_dlp_jobs_editor = projects.IAMMember(
            "sa_inspector_dlp_jobs_editor",
            project=self.var.project,
            role="roles/dlp.jobsEditor",
            member= self.sa_inspector.email.apply(lambda e: f"serviceAccount:{e}"),
            opts=self.child_opts
        )

        # Grant sa_inspector access to read dlp templates
        self.sa_inspector_dlp_template_reader = projects.IAMMember(
            "sa_inspector_dlp_template_reader",
            project=self.var.project,
            role="roles/dlp.inspectTemplatesReader",
            member= self.sa_inspector.email.apply(lambda e: f"serviceAccount:{e}"),
            opts=self.child_opts
        )


        