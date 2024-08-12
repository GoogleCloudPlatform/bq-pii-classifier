from typing import List, Optional, Union
from pulumi import Output
from pydantic import BaseModel, ConfigDict

class EnvironmentVariable(BaseModel):
    name : str
    value : Union[str , bool , int, Output[str]]
    model_config = ConfigDict(arbitrary_types_allowed=True)

class CloudRunArgs(BaseModel):
    project : str
    region : str
    service_image : str
    service_name : str
    service_account_email : Output[str]
    invoker_service_account_email : Output[str]
    max_memory : str = "1Gi"
    # Dispatcher could take time to list large number of tables
    timeout_seconds : int
    max_containers : int = 1
    max_requests_per_container : int = 80
    max_cpu :int = 2
    environment_variables : List[EnvironmentVariable]
    model_config = ConfigDict(arbitrary_types_allowed=True)

