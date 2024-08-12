from pulumi import Output
from pydantic import BaseModel, ConfigDict
from typing import Any, List, Union

class PubSubArgs(BaseModel):
    project_id : str
    subscription_endpoint : Output[Any]
    subscription_name : str
    subscription_service_account : Output[str]
    topic : str
    topic_publishers_sa_emails : List[Union[str, Output[str]]]
    # use a deadline large enough to process BQ listing for large scopes
    subscription_ack_deadline_seconds : int
    # avoid resending dispatcher messages if things went wrong and the msg was NAK (e.g. timeout expired, app error, etc)
    # min value must be at equal to the ack_deadline_seconds
    subscription_message_retention_duration : str
    model_config = ConfigDict(arbitrary_types_allowed=True)