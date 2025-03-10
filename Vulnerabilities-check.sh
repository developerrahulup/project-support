#!/bin/bash

# Configuration
S3_BUCKET="prod-exo-gva-s3-release-dda9f30222fec0de"
S3_PREFIX="tg-solutions-binaries/"
S3_CONFIG="s3cfg.ini"
DOWNLOAD_DIR="./downloads"
EXTRACT_DIR="./extracted"

# Ensure directories exist
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$EXTRACT_DIR"

# Function to get the latest version
get_latest_version() {
    echo "Fetching list of versions from S3..."
    s3cmd ls "s3://$S3_BUCKET/$S3_PREFIX" -c "$S3_CONFIG" | \
    grep -oE "tg-solutions-v3\.36\.[0-9]+-binaries-signed\.tgz" | \
    grep -oE "3\.36\.[0-9]+" | \
    sort -V | tail -n 1 
}

# Function to download and extract the latest version
download_and_extract() {
    local version="$1"
    local file_name="tg-solutions-v$version-binaries-signed.tgz"
    local s3_key="$S3_PREFIX$file_name"
    local local_path="$DOWNLOAD_DIR/$file_name"

    echo "Downloading $s3_key..."
    s3cmd get "s3://$S3_BUCKET/$s3_key" "$local_path" -c "$S3_CONFIG"

    echo "Extracting $local_path..."
    tar -zxf "$local_path" -C "$EXTRACT_DIR"
}

# Function to check vulnerabilities
check_vulnerabilities() {
    local version="$1"
    local json_file="$EXTRACT_DIR/tg-solutions-v$version-binaries-signed/tg-solutions/tg-protect-gui-v$version/reports/vulnerabilities/tg-protect-gui-v$version-vulnerabilities.json"

    if [[ ! -f "$json_file" ]]; then
        echo "Error: Vulnerabilities file not found: $json_file"
        exit 1
    fi

    echo "Checking vulnerabilities in $json_file..."
    high=$(jq -r '.High' "$json_file")
    critical=$(jq -r '.Critical' "$json_file")

    echo "High: $high, Critical: $critical"

    if [[ $high -gt 3 || $critical -gt 3 ]]; then
        echo "Invalid: High or Critical vulnerabilities exceed the threshold."
        exit 1
    else
        echo "Valid: Vulnerabilities are within the acceptable range."
    fi
}

# Main script
echo "Starting script..."

# Get the latest version
latest_version=$(get_latest_version)
if [[ -z "$latest_version" ]]; then
    echo "Error: No versions found in S3 bucket."
    exit 1
fi
echo "Latest version found: $latest_version"

# Download and extract the latest version
download_and_extract "$latest_version"

# Check vulnerabilities
check_vulnerabilities "$latest_version"

echo "Script completed successfully."
