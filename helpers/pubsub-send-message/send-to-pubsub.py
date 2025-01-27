import argparse
from google.cloud import pubsub_v1
import base64


def publish_message(topic_path, base64_message_data):
    """Publishes a message to the specified Pub/Sub topic.

    Args:
        topic_path: The full path to the Pub/Sub topic (e.g., "projects/your-project/topics/your-topic").
        message_data: The message data to send.  Can be a string or bytes.
    """

    publisher = pubsub_v1.PublisherClient()

    try:
        message_bytes = base64.b64decode(base64_message_data)
        future = publisher.publish(topic_path, message_bytes)
        message_id = future.result()
        print(f"Published message ID: {message_id}")

    except Exception as e:
        print(f"Error publishing message: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Publish a message to a Pub/Sub topic.")
    parser.add_argument("topic_path", help="The full path to the Pub/Sub topic.")
    parser.add_argument("message_data", help="The message data to send.")  # Can be a string or bytes representation.
    args = parser.parse_args()

    publish_message(args.topic_path, args.message_data)

