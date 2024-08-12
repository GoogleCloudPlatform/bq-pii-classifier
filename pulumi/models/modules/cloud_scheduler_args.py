from pulumi import Output
from pydantic import BaseModel, ConfigDict
from typing import List, Union

class CloudSchedulerArgs(BaseModel):
    project : str
    region : str
    scheduler_name : str
    target_uri : Union[str , Output[str]]
    tables_include_list : List[str]
    datasets_include_list : List[str]
    projects_include_list : List[str]
    datasets_exclude_list : List[str]
    tables_exclude_list : List[str]
    cron_expression : str
    model_config = ConfigDict(arbitrary_types_allowed=True)