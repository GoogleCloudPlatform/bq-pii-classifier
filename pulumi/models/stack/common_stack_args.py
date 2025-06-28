from pydantic import BaseModel
from typing import List, Optional
from models.modules.clasification_taxonomy_args import ClasificationTaxonomyArgs
from models.stack.domain_mapping import DomainMapping

class CommonStackArgs(BaseModel):
    classification_taxonomy : Optional[List[ClasificationTaxonomyArgs]]
    created_taxonomy : List[str] = []
    created_children_tags : List = []
    created_parent_tags : List = []
    cloud_scheduler_account : str 
    cron_expression : str
    datasets_exclude_list : List[str]
    datasets_include_list : List[str]
    dispatcher_service_image : str
    dlp_service_account : str
    domain_mapping : List[DomainMapping]
    iam_mapping : dict
    is_dry_run : bool
    project : str
    projects_include_list : List[str]
    compute_region : str
    data_region : str
    tables_exclude_list : List[str]
    tables_include_list : List[str]
    tagger_service_image : str
    bigquery_dataset_name : str
    dispatcher_pubsub_sub : str
    dispatcher_pubsub_topic : str
    dispatcher_service_name : str
    log_sink_name : str
    sa_tagger : str
    sa_tagger_tasks : str
    scheduler_name : str
    tagger_pubsub_sub : str
    tagger_pubsub_topic : str
    tagger_role : str
    tagger_service_name : str
    is_auto_dlp_mode : bool
    auto_dlp_results_table_name : str
    standard_dlp_results_table_name : str
    sa_tagging_dispatcher : str
    sa_tagging_dispatcher_tasks : str
    data_catalog_taxonomy_activated_policy_types : List[str]
    gcs_flags_bucket_name : str

    dispatcher_service_timeout_seconds : int
    dispatcher_subscription_ack_deadline_seconds : int
    dispatcher_subscription_message_retention_duration : str
    tagger_service_timeout_seconds : int
    tagger_subscription_ack_deadline_seconds : int
    tagger_subscription_message_retention_duration : str
    promote_mixed_info_types : bool