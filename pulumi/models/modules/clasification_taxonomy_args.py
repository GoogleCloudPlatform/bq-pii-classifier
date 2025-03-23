from pydantic import BaseModel

class ClasificationTaxonomyArgs(BaseModel):
    info_type : str = "NA"
    info_type_category : str  = "" # (standard | custom)
    policy_tag : str
    classification : str