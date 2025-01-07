#!/bin/bash

# Base directory
BASE_DIR="/home/ec2-user/taurus-binaries/binaries-2024*"

# Loop through all matching directories
for FOLDER in $BASE_DIR; do
  # Dynamically find the tg-solutions directory with the version
  TG_SOLUTIONS_DIR=$(find "$FOLDER/deflate" -type d -name "tg-solutions-*-binaries-signed" | head -n 1)
  if [[ -z "$TG_SOLUTIONS_DIR" ]]; then
    echo "tg-solutions directory not found in $FOLDER"
    continue
  fi

  RELEASE_FILE="$TG_SOLUTIONS_DIR/tg-solutions/release.yaml"
  TG_VALIDATORD_DIR=$(find "$TG_SOLUTIONS_DIR/tg-solutions" -type d -name "tg-validatord-v*" | head -n 1)
  
  if [[ -z "$TG_VALIDATORD_DIR" ]]; then
    echo "tg-validatord directory not found in $TG_SOLUTIONS_DIR"
    continue
  fi

  TG_VALIDATORD_FILE="$TG_VALIDATORD_DIR/tg-validatord"

  # Check if both files exist
  if [[ -f "$RELEASE_FILE" && -f "$TG_VALIDATORD_FILE" ]]; then
    echo "Processing folder: $FOLDER"

    # Extract expected checksum from release.yaml
    EXPECTED_CHECKSUM=$(grep "tg-validatord" "$RELEASE_FILE" | awk '{print $2}')

    # Calculate the actual checksum of tg-validatord
    ACTUAL_CHECKSUM=$(sha256sum "$TG_VALIDATORD_FILE" | awk '{print $1}')

    # Compare checksums
    if [[ "$EXPECTED_CHECKSUM" == "$ACTUAL_CHECKSUM" ]]; then
      echo "Checksums match for tg-validatord in folder: $FOLDER"
    else
      echo "Checksum mismatch in folder: $FOLDER"
      echo "Expected: $EXPECTED_CHECKSUM"
      echo "Found: $ACTUAL_CHECKSUM"
    fi
  else
    echo "Missing release.yaml or tg-validatord file in folder: $FOLDER"
  fi
done
