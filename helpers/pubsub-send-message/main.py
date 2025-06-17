import argparse
from google.cloud import pubsub_v1
import base64


def publish_messages(topic_path, *message_data_list):
    """Publishes a message to the specified Pub/Sub topic.

    Args:
        topic_path: The full path to the Pub/Sub topic (e.g., "projects/your-project/topics/your-topic").
        message_data: The message data to send.  Can be a string or bytes.
    """

    publisher = pubsub_v1.PublisherClient()
    futures = []  # For asynchronous publishing

    for base64_message_data in message_data_list:
        try:
            message_bytes = base64.b64decode(base64_message_data)
            future = publisher.publish(topic_path, message_bytes)
            futures.append(future)
            print(f"Scheduled message: {base64_message_data[:20]}...") # Print a snippet

        except Exception as e:
            print(f"Error scheduling message: {e}")

    # Wait for all publish operations to complete
    for future in futures:
        try:
            message_id = future.result()
            print(f"Published message ID: {message_id}")
        except Exception as e:
            print(f"Error publishing message: {e}")

    print(f"Published {len(message_data_list)} messages.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Publish one or more messages to a Pub/Sub topic.")
    parser.add_argument("topic_path", help="The full path to the Pub/Sub topic.")
    parser.add_argument("message_data", nargs="+", help="The message data to send (one or more, base64 encoded).")  # nargs="+"

    args = parser.parse_args()

    publish_messages(args.topic_path, *args.message_data)  # Unpack the list

