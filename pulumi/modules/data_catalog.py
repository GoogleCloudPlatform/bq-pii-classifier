import pulumi
import pulumi_gcp as gcp
from models.modules.data_catalog_args import DataCatalogArgs

class DataCatalog(pulumi.ComponentResource):
    def __init__(self, var: DataCatalogArgs, opts: None):
        super().__init__("custom:modules:DataCatalog", var.domain, None, opts= opts)
        self.child_opts = pulumi.ResourceOptions(parent=self)

        self.var = var
        self.__create()
        
    ### Create One  taxonomy and it's hierarchy
    def __create_taxonomy(self,domain: str) -> gcp.datacatalog.Taxonomy:
        var = self.var
        taxonomy = gcp.datacatalog.Taxonomy(
            "domain_taxonomy",
            region= var.region,
            project=var.project,
            display_name=f"{domain} Taxonomy",
            description=f"A collection of policy tags assigned by BQ security classifier for domain '{domain}'",
            activated_policy_types=var.data_catalog_taxonomy_activated_policy_types,
            opts=self.child_opts
        )

        # Export the Taxonomy ID
        return taxonomy

    def __create(self):
            var = self.var
            domain_taxonomy = self.__create_taxonomy(domain=var.domain)

            # Get distinct list of parents and sort them
            parent_nodes = sorted(list(set([entry.classification for entry in var.classification_taxonomy])))

            # Create parent policy tags
            parent_tags = [
            gcp.datacatalog.PolicyTag(
                f"parent_tag_{index}",
                taxonomy=domain_taxonomy.id,
                display_name=parent_node,
                description=pulumi.Output.concat(var.domain, " | ", parent_node),
                opts=self.child_opts
            )
            for index, parent_node in enumerate(parent_nodes)
            ]

            # Create children policy tags
            children_tags = [
            gcp.datacatalog.PolicyTag(
                f"children_tag_{index}",
                taxonomy=domain_taxonomy.id,
                parent_policy_tag=parent_tags[
                parent_nodes.index(entry.classification)
                ].id,
                display_name=entry.policy_tag,
                description=pulumi.Output.concat(var.domain, " | ", entry.info_type),
                opts=self.child_opts
            )
            for index, entry in enumerate(var.classification_taxonomy)
            ]
            #self.register_outputs({
            #    f"{var.domain}domain_taxonomy_id": domain_taxonomy.id,
            #    f"{var.domain}parent_tags": [{"id" : tag.id, "display_name" : tag.display_name, "domain" : var.domain } for tag in parent_tags],
            #    f"{var.domain}children_tags": [{"policy_tag_id" : tag.id, "display_name": tag.display_name, "domain": var.domain } for tag in children_tags]
            #})

            self.parent_tags = parent_tags
            self.children_tags = children_tags