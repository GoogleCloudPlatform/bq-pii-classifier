from pydantic import BaseModel
from typing import List
from models.modules.clasification_taxonomy_args import ClasificationTaxonomyArgs

class DataCatalogArgs(BaseModel):
    project : str
    region : str
    domain : str
    classification_taxonomy : List[ClasificationTaxonomyArgs]
    data_catalog_taxonomy_activated_policy_types : List[str]


