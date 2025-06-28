from pulumi import Output
from pydantic import BaseModel, ConfigDict
from typing import List


class TaxonomyParentTags(BaseModel):
    id : str
    domain : str
    display_name : str
    
class IAMArgs(BaseModel):
    project : str
    sa_tagger : str
    sa_tagger_tasks : str
    taxonomy_parent_tags : List[Output[TaxonomyParentTags]]
    iam_mapping : dict
    dlp_service_account : str
    tagger_role : str
    sa_tagging_dispatcher : str
    sa_tagging_dispatcher_tasks : str
    bq_results_dataset : Output[str]
    model_config = ConfigDict(arbitrary_types_allowed=True)
