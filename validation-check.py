import boto3
import subprocess
import json
import os
import re
from distutils.version import StrictVersion

# S3 Configuration
S3_BUCKET = "prod-exo-gva-s3-release-dda9f30222fec0de"
S3_PREFIX = "tg-solutions-binaries/"
S3_CONFIG = "s3cfg.ini"

# Local paths
DOWNLOAD_DIR = "./downloads"
EXTRACT_DIR = "./extracted"

# Ensure directories exist
os.makedirs(DOWNLOAD_DIR, exist_ok=True)
os.makedirs(EXTRACT_DIR, exist_ok=True)

def get_latest_version(s3_client):
    """Get the latest version of tg-solutions binaries from S3."""
    response = s3_client.list_objects_v2(Bucket=S3_BUCKET, Prefix=S3_PREFIX)
    versions = []

    for obj in response.get("Contents", []):
        key = obj["Key"]
        match = re.search(r"tg-solutions-v(\d+\.\d+\.\d+)-binaries-signed\.tgz", key)
        if match:
            versions.append(match.group(1))

    if not versions:
        raise ValueError("No versions found in S3 bucket.")

    # Sort versions using StrictVersion to handle semantic versioning
    latest_version = sorted(versions, key=StrictVersion, reverse=True)[0]
    return latest_version

def download_and_extract(s3_client, version):
    """Download and extract the latest version of the binary."""
    file_name = f"tg-solutions-v{version}-binaries-signed.tgz"
    s3_key = f"{S3_PREFIX}{file_name}"
    local_path = os.path.join(DOWNLOAD_DIR, file_name)

    # Download the file
    print(f"Downloading {s3_key}...")
    s3_client.download_file(S3_BUCKET, s3_key, local_path)

    # Extract the file
    print(f"Extracting {local_path}...")
    subprocess.run(["tar", "-zxf", local_path, "-C", EXTRACT_DIR], check=True)

def check_vulnerabilities(version):
    """Check the vulnerabilities JSON file for High and Critical values."""
    json_file = os.path.join(
        EXTRACT_DIR,
        f"tg-solutions-v{version}-binaries-signed/tg-solutions/tg-protect-gui-v{version}/reports/vulnerabilities/tg-protect-gui-v{version}-vulnerabilities.json"
    )

    if not os.path.exists(json_file):
        raise FileNotFoundError(f"Vulnerabilities file not found: {json_file}")

    with open(json_file, "r") as f:
        data = json.load(f)

    high = data.get("High", 0)
    critical = data.get("Critical", 0)

    print(f"High: {high}, Critical: {critical}")

    if high > 3 or critical > 3:
        print("Invalid: High or Critical vulnerabilities exceed the threshold.")
        return False
    else:
        print("Valid: Vulnerabilities are within the acceptable range.")
        return True

def main():
    # Initialize S3 client
    s3_client = boto3.client("s3")

    # Get the latest version
    latest_version = get_latest_version(s3_client)
    print(f"Latest version found: {latest_version}")

    # Download and extract the latest version
    download_and_extract(s3_client, latest_version)

    # Check vulnerabilities
    is_valid = check_vulnerabilities(latest_version)
    if not is_valid:
        exit(1)  # Exit with error code if invalid

if __name__ == "__main__":
    main()
