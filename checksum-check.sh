#!/bin/bash

# Base directory
BASE_DIR="/home/ec2-user/taurus-binaries/binaries-2024*"

# Log file for missing checksums
MISSING_CHECKSUM_LOG="/home/ec2-user/missing_checksums.log"
> "$MISSING_CHECKSUM_LOG"  # Clear previous log if exists

# List of components to validate
COMPONENTS=("tg-validatord" "tg-gated" "tg-vaultd" "tg-protect-gui" "tg-protect-usermanager")

# Loop through all matching directories
for FOLDER in $BASE_DIR; do
  TG_SOLUTIONS_DIR=$(find "$FOLDER/deflate" -type d -name "tg-solutions-*-binaries-signed" | head -n 1)
  if [[ -z "$TG_SOLUTIONS_DIR" ]]; then
    echo "tg-solutions directory not found in $FOLDER"
    continue
  fi

  RELEASE_FILE="$TG_SOLUTIONS_DIR/tg-solutions/release.yaml"

  # For each defined component, check its checksum
  for COMPONENT in "${COMPONENTS[@]}"; do
    # Find the versioned directory for the component (the version suffix is in the folder name)
    COMPONENT_DIR=$(find "$TG_SOLUTIONS_DIR/tg-solutions" -type d -name "*$COMPONENT-v*" | head -n 1)

    # Get the component file (the component file name is the same as the component name)
    COMPONENT_FILE="$COMPONENT_DIR/$COMPONENT"
    if [[ -f "$COMPONENT_FILE" ]]; then
      # Calculate the checksum for the component file
      ACTUAL_CHECKSUM=$(sha256sum "$COMPONENT_FILE" | awk '{print $1}')
      
      # Search for the checksum in release.yaml
      if grep -q "$ACTUAL_CHECKSUM" "$RELEASE_FILE"; then
        echo "Checksum matched for $COMPONENT_FILE in $FOLDER"
      else
        echo "No match found for checksum of $COMPONENT_FILE in $FOLDER" >> "$MISSING_CHECKSUM_LOG"
      fi
    else
      echo "$COMPONENT_FILE not found in $FOLDER" >> "$MISSING_CHECKSUM_LOG"
    fi
  done
done

# Check if there are missing checksums and notify
if [[ -s "$MISSING_CHECKSUM_LOG" ]]; then
  echo "Missing checksums logged in: $MISSING_CHECKSUM_LOG"
else
  echo "All checksums are verified successfully."
fi
