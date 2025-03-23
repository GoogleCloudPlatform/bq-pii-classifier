from pulumi import Output
from pydantic import BaseModel, ConfigDict
from typing import List, Union
from models.modules.clasification_taxonomy_args import ClasificationTaxonomyArgs
from models.stack.domain_mapping import DomainMapping

class InspectionStackArgs(BaseModel):
    project : str
    compute_region : str
    data_region : str
    sa_inspection_dispatcher : str
    sa_inspection_dispatcher_tasks : str
    sa_inspector: str
    sa_inspector_tasks : str
    scheduler_name : str
    dispatcher_service_name : str
    inspector_service_name : str
    dispatcher_pubsub_topic : str  
    dispatcher_pubsub_sub : str
    inspector_pubsub_topic : str
    inspector_pubsub_sub : str
    dispatcher_service_image : str
    inspector_service_image : str

    tables_include_list : List[str]
    datasets_include_list : List[str]
    projects_include_list : List[str]

    datasets_exclude_list : List[str]
    tables_exclude_list : List[str]

    cloud_scheduler_account : str
    bigquery_dataset_name : Output[str]
    standard_dlp_results_table_name : str
    dlp_inspection_template_id : Output[str]
    cron_expression : str
    table_scan_limits_json_config : str
    tagger_topic_id : Output[str]
    dlp_min_likelihood : str
    dlp_max_findings_per_item : Union[str, int]
    dlp_sampling_method : Union[str, int]
    gcs_flags_bucket_name : Output[str]
    dispatcher_service_timeout_seconds : int
    dispatcher_subscription_ack_deadline_seconds : int
    dispatcher_subscription_message_retention_duration : str
    inspector_service_timeout_seconds : int
    inspector_subscription_ack_deadline_seconds : int
    inspector_subscription_message_retention_duration : str
    model_config = ConfigDict(arbitrary_types_allowed=True)