#!/bin/bash

# Base directory
BASE_DIR="/home/ec2-user/taurus-binaries/binaries-2024*"

# Log file for missing checksums
MISSING_CHECKSUM_LOG="/home/ec2-user/missing_checksums.log"
> "$MISSING_CHECKSUM_LOG"  # Clear previous log if exists

# List of components to validate where checksum is mentioned directly in release.yaml
COMPONENTS_DIRECT_CHECKSUM=("tg-validatord" "tg-gated" "tg-vaultd")

# List of components where we need to check the actual checksum in release.yaml
COMPONENTS_CHECK_ACTUAL_CHECKSUM=("tg-protect-gui" "tg-protect-usermanager")

# Loop through all matching directories
for FOLDER in $BASE_DIR; do
  # Dynamically find the tg-solutions directory with the version
  TG_SOLUTIONS_DIR=$(find "$FOLDER/deflate" -type d -name "tg-solutions-*-binaries-signed" | head -n 1)
  if [[ -z "$TG_SOLUTIONS_DIR" ]]; then
    echo "tg-solutions directory not found in $FOLDER"
    continue
  fi

  RELEASE_FILE="$TG_SOLUTIONS_DIR/tg-solutions/release.yaml"

  # Check if release.yaml file exists
  if [[ ! -f "$RELEASE_FILE" ]]; then
    echo "Missing release.yaml in folder: $FOLDER"
    continue
  fi

  # For components where checksum is directly mentioned in release.yaml
  for COMPONENT in "${COMPONENTS_DIRECT_CHECKSUM[@]}"; do
    # Find the file for the component
    COMPONENT_FILE=$(find "$TG_SOLUTIONS_DIR/tg-solutions" -type f -name "$COMPONENT" | head -n 1)

    if [[ -z "$COMPONENT_FILE" ]]; then
      echo "$COMPONENT file not found in $TG_SOLUTIONS_DIR"
      continue
    fi

    # Extract expected checksum from release.yaml
    EXPECTED_CHECKSUM=$(grep "$COMPONENT" "$RELEASE_FILE" | awk '{print $2}')

    if [[ -z "$EXPECTED_CHECKSUM" ]]; then
      echo "Checksum for $COMPONENT not found in $RELEASE_FILE"
      continue
    fi

    # Get the actual checksum of the component file
    ACTUAL_CHECKSUM=$(sha256sum "$COMPONENT_FILE" | awk '{print $1}')

    # Compare checksums
    if [[ "$EXPECTED_CHECKSUM" == "$ACTUAL_CHECKSUM" ]]; then
      echo "Checksums match for $COMPONENT in folder: $FOLDER"
    else
      echo "Checksum mismatch for $COMPONENT in folder: $FOLDER"
      echo "Expected: $EXPECTED_CHECKSUM"
      echo "Found: $ACTUAL_CHECKSUM"
    fi
  done

  # For components where we need to check the actual checksum in release.yaml
  for COMPONENT in "${COMPONENTS_CHECK_ACTUAL_CHECKSUM[@]}"; do
    # Find the file for the component
    COMPONENT_FILE=$(find "$TG_SOLUTIONS_DIR/tg-solutions" -type f -name "$COMPONENT" | head -n 1)

    if [[ -z "$COMPONENT_FILE" ]]; then
      echo "$COMPONENT file not found in $TG_SOLUTIONS_DIR"
      continue
    fi

    # Get the actual checksum of the component file
    ACTUAL_CHECKSUM=$(sha256sum "$COMPONENT_FILE" | awk '{print $1}')

    # Search for the checksum in release.yaml
    EXPECTED_CHECKSUM=$(grep -oP "(?<=checksum:\s)[a-f0-9]{64}" "$RELEASE_FILE" | grep -w "$ACTUAL_CHECKSUM")

    # Check if checksum is found in release.yaml
    if [[ -z "$EXPECTED_CHECKSUM" ]]; then
      # Checksum not found, log as missing or mismatch
      echo "Checksum for $COMPONENT_FILE is missing or doesn't match in $RELEASE_FILE"
      echo "$COMPONENT_FILE checksum missing or mismatched in release.yaml for folder: $FOLDER" >> "$MISSING_CHECKSUM_LOG"
    else
      # Checksum matches, print success message
      echo "Checksum matched for $COMPONENT_FILE in folder: $FOLDER"
    fi
  done
done

# Check if there are missing checksums and notify
if [[ -s "$MISSING_CHECKSUM_LOG" ]]; then
  echo "Missing checksums logged in: $MISSING_CHECKSUM_LOG"
else
  echo "All checksums are verified successfully."
fi
