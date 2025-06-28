"""A Google Cloud Python Pulumi program"""
from stacks.data_lake_dlp import DataLakeDLP

if __name__ == "__main__":
    pii = DataLakeDLP("data_lake_dlp")
    pii.deploy()