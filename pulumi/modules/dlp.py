
from models.modules.clasification_taxonomy_args import ClasificationTaxonomyArgs
from typing import List
import pulumi_google_native as google
import pulumi

class DataLossPrevention(pulumi.ComponentResource):
    def __init__(self, project_id: str, region: str, classification_taxonomy: List[ClasificationTaxonomyArgs], opts: None):
        super().__init__("custom:modules:DataLossPrevention", "DataLossPrevention", None, opts=opts)
        self.child_opts = pulumi.ResourceOptions(parent=self)
        self.project_id = project_id
        self.region = region
        self.classification_taxonomy = classification_taxonomy
        self.dlp_region = "europe" if region == "eu" else region 
        self.__deploy()

    def __deploy(self):
        
        inspection_template = google.dlp.v2.InspectTemplate(
            "inspection_template",
            project=self.project_id,
            location=self.dlp_region,
            
            template_id="bq_security_classifier_inspection_template",
            description="DLP Inspection template used by the BQ security classifier app",
            display_name="bq_security_classifier_inspection_template",
             
            inspect_config={
                "min_likelihood": "LIKELY",
                "info_types": [
                {
                    "name": info_types.info_type,
                }
                for info_types in self.classification_taxonomy
                if info_types.info_type_category.lower() == "standard"
                ],
                "custom_info_types": [
                {
                    "info_type": {
                    "name": "CT_PAYMENT_METHOD",
                    },
                    "likelihood": "LIKELY",
                    "dictionary": {
                    "word_list": {
                        "words": ["Debit Card", "Credit Card"],
                    },
                    },
                },
                ],
                "rule_set": [
                {
                    "info_types": [
                    {
                        "name": "EMAIL_ADDRESS",
                    },
                    ],
                    "rules": [
                    {
                        "exclusion_rule": {
                        "regex": {
                            "pattern": ".+@excluded-example.com",
                        },
                        "matching_type": "MATCHING_TYPE_FULL_MATCH",
                        },
                    },
                    ],
                },
                {
                    "info_types": [
                    {
                        "name": "STREET_ADDRESS",
                    },
                    ],
                    "rules": [
                    {
                        "hotword_rule": {
                        "hotword_regex": {
                            "pattern": "(street_name|street_address|delivery_address|house_number|city|zip)",
                        },
                        "proximity": {
                            "window_before": 1,
                        },
                        "likelihood_adjustment": {
                            "fixed_likelihood": "VERY_LIKELY",
                        },
                        },
                    },
                    ],
                },
                ],
                "include_quote": False,
            },
            opts= self.child_opts
            )
        
        self.register_outputs({
            "inspection_template": inspection_template,
            "inspection_template_id": inspection_template.template_id
        })
        self.inspection_template = inspection_template
        