#!/bin/bash

# Base directory
BASE_DIR="/home/ec2-user/taurus-binaries/binaries-2024*"

# Log file for missing checksums
MISSING_CHECKSUM_LOG="/home/ec2-user/missing_checksums.log"
> "$MISSING_CHECKSUM_LOG"  # Clear previous log if exists

# Loop through all matching directories
for FOLDER in $BASE_DIR; do
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

  # Loop through each component in tg-solutions folder
  for COMPONENT_DIR in "$TG_SOLUTIONS_DIR/tg-solutions"/*; do
    # Skip directories that don't match the pattern
    if [[ ! -d "$COMPONENT_DIR" ]]; then
      continue
    fi

    COMPONENT=$(basename "$COMPONENT_DIR")
    COMPONENT_FILE="$COMPONENT_DIR/$COMPONENT"

    # Check if component file exists
    if [[ -f "$COMPONENT_FILE" ]]; then
      # Get the actual checksum of the component file
      ACTUAL_CHECKSUM=$(sha256sum "$COMPONENT_FILE" | awk '{print $1}')
      
      # Check if the checksum is mentioned in the release.yaml file
      EXPECTED_CHECKSUM=$(grep -E "$COMPONENT" "$RELEASE_FILE" | awk '{print $2}')
      
      if [[ -z "$EXPECTED_CHECKSUM" ]]; then
        echo "Checksum for $COMPONENT not found in release.yaml" >> "$MISSING_CHECKSUM_LOG"
      elif [[ "$EXPECTED_CHECKSUM" == "$ACTUAL_CHECKSUM" ]]; then
        echo "Checksum matched for $COMPONENT in $FOLDER"
      else
        echo "Checksum mismatch for $COMPONENT in $FOLDER" >> "$MISSING_CHECKSUM_LOG"
      fi
    else
      echo "$COMPONENT file not found in $FOLDER" >> "$MISSING_CHECKSUM_LOG"
    fi
  done
done

# Check if there are missing checksums and notify
if [[ -s "$MISSING_CHECKSUM_LOG" ]]; then
  echo "Missing checksums logged in: $MISSING_CHECKSUM_LOG"
else
  echo "All checksums are verified successfully."
fi
