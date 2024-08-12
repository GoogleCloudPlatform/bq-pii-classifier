from pydantic import BaseModel
from typing import List


class Domain(BaseModel):
    name: str
    domain: str

class DomainMapping(BaseModel):
    project : str
    domain : str
    datasets : List[Domain]  #  // leave empty if no dataset overrides is required for this project
