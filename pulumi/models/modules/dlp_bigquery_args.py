from pulumi import Output
from pydantic import BaseModel, ConfigDict
from typing import List, Dict, Tuple

class DLPBigqueryArgs(BaseModel):
    project: str
    region: str
    dataset: str
    logging_sink_sa: Output[str]
    created_policy_tags: List[Output]
    created_parent_tags: List[Output]
    dataset_domain_mapping: List[Dict[str, str]]
    projects_domain_mapping: List[Dict[str, str]]
    standard_dlp_results_table_name: str
    model_config = ConfigDict(arbitrary_types_allowed=True)