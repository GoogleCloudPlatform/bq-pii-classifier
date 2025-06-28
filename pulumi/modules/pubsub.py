import pulumi
from models.modules.pubsub_args import PubSubArgs
from pulumi_gcp import pubsub

class PubSub(pulumi.ComponentResource):
    def __init__(self, var: PubSubArgs, opts: None):
        super().__init__(f"custom:modules:PubSub{var.subscription_name}", f"PubSub{var.subscription_name}", None, opts=opts)
        self.var = var
        self.child_opts = pulumi.ResourceOptions(parent=self)
        self.__deploy()
    
    def __deploy(self):
        topic = pubsub.Topic(
            "topic",
            project=self.var.project_id,
            name=self.var.topic,
            opts=self.child_opts)
        self.topic_id = topic.id

        pubsub.Subscription("subscription",
                            project=self.var.project_id,
            name=self.var.subscription_name,
            topic=topic.id,
            ack_deadline_seconds=self.var.subscription_ack_deadline_seconds,
            message_retention_duration=self.var.subscription_message_retention_duration,
            retain_acked_messages=False,
            enable_message_ordering=False,
            enable_exactly_once_delivery=False,
            expiration_policy=pubsub.SubscriptionExpirationPolicyArgs(
                ttl=""),
            
            push_config=pubsub.SubscriptionPushConfigArgs(
                push_endpoint=self.var.subscription_endpoint,
                oidc_token=pubsub.SubscriptionPushConfigOidcTokenArgs(
                    service_account_email=self.var.subscription_service_account,
                )),
            opts=self.child_opts
        )

        for sa in self.var.topic_publishers_sa_emails:
            if isinstance(sa, pulumi.Output):
                sa.apply(lambda sa:
                         pubsub.TopicIAMMember(f"sa_topic_publisher:{sa}",
                              project=self.var.project_id,
                              topic= topic.id,
                              role="roles/pubsub.publisher",
                              member=f"serviceAccount:{sa}",
                              opts=self.child_opts))
                
            else:
                pubsub.TopicIAMMember(f"sa_topic_publisher:{sa}",
                              project=self.var.project_id,
                              topic= topic.id,
                              role="roles/pubsub.publisher",
                              member=f"serviceAccount:{sa}",
                              opts=self.child_opts)