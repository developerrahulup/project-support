#!/bin/bash

# Base directory
BASE_DIR="/home/ec2-user/taurus-binaries/binaries-2024*"

# List of components to validate
COMPONENTS=("tg-validatord:" "tg-gated:" "tg-vaultd:" "tg-protect-gui:" "tg-protect-usermanager:")

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

  # Loop over each component to check its checksum
  for COMPONENT in "${COMPONENTS[@]}"; do
    # Find the directory of the component
    COMPONENT_DIR=$(find "$TG_SOLUTIONS_DIR/tg-solutions" -type d -name "$COMPONENT-v*" | head -n 1)

    if [[ -z "$COMPONENT_DIR" ]]; then
      echo "$COMPONENT directory not found in $TG_SOLUTIONS_DIR"
      continue
    fi

    # Get the file for the component
    COMPONENT_FILE="$COMPONENT_DIR/$COMPONENT"

    # Extract expected checksum from release.yaml
    EXPECTED_CHECKSUM=$(grep "$COMPONENT" "$RELEASE_FILE" | awk '{print $2}')

    if [[ -z "$EXPECTED_CHECKSUM" ]]; then
      echo "Checksum for $COMPONENT not found in $RELEASE_FILE"
      continue
    fi

    # Calculate the actual checksum of the component
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
done
