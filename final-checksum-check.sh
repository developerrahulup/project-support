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

  # For components where checksum is directly mentioned in release.yaml
  for COMPONENT in "tg-validatord" "tg-gated" "tg-vaultd"; do
    # Find the directory for the component (the version info is in the parent folder name)
    COMPONENT_DIR=$(find "$TG_SOLUTIONS_DIR/tg-solutions" -type d -name "*$COMPONENT*" | head -n 1)

    if [[ -z "$COMPONENT_DIR" ]]; then
      echo "$COMPONENT directory not found in $TG_SOLUTIONS_DIR" >> "$MISSING_CHECKSUM_LOG"
      continue
    fi

    # Get the component file
    COMPONENT_FILE="$COMPONENT_DIR/$COMPONENT"
    if [[ -f "$COMPONENT_FILE" ]]; then
      EXPECTED_CHECKSUM=$(grep "$COMPONENT" "$RELEASE_FILE" | awk '{print $2}')
      ACTUAL_CHECKSUM=$(sha256sum "$COMPONENT_FILE" | awk '{print $1}')
      if [[ "$EXPECTED_CHECKSUM" == "$ACTUAL_CHECKSUM" ]]; then
        echo "Checksum matched for $COMPONENT in $FOLDER"
      else
        echo "Checksum mismatch for $COMPONENT in $FOLDER" >> "$MISSING_CHECKSUM_LOG"
      fi
    else
      echo "$COMPONENT file not found in $FOLDER" >> "$MISSING_CHECKSUM_LOG"
    fi
  done

  # For components where we need to check actual checksum in release.yaml
  for COMPONENT in "tg-protect-gui" "tg-protect-usermanager"; do
    # Find the directory for the component (the version info is in the parent folder name)
    COMPONENT_DIR=$(find "$TG_SOLUTIONS_DIR/tg-solutions" -type d -name "*$COMPONENT*" | head -n 1)

    if [[ -z "$COMPONENT_DIR" ]]; then
      echo "$COMPONENT directory not found in $TG_SOLUTIONS_DIR" >> "$MISSING_CHECKSUM_LOG"
      continue
    fi

    # Get the component file
    COMPONENT_FILE="$COMPONENT_DIR/$COMPONENT"
    if [[ -f "$COMPONENT_FILE" ]]; then
      ACTUAL_CHECKSUM=$(sha256sum "$COMPONENT_FILE" | awk '{print $1}')
      if grep -q "$ACTUAL_CHECKSUM" "$RELEASE_FILE"; then
        echo "Checksum matched for $COMPONENT in $FOLDER"
      else
        echo "Checksum mismatch or not found for $COMPONENT in $FOLDER" >> "$MISSING_CHECKSUM_LOG"
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
