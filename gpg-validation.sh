#!/bin/bash

# Input Arguments
TARGET_PATH="$1"      # Path containing the files (e.g., tg-solution-v2.54.16-binaries-signuture)
EC2_USER="$2"         # EC2 username and IP (e.g., ec2-user@<EC2-IP>)
SSH_KEY="$3"          # Path to SSH private key file

# Validate inputs
if [ -z "$TARGET_PATH" ] || [ -z "$EC2_USER" ] || [ -z "$SSH_KEY" ]; then
  echo "Usage: $0 <path> <ec2-user@ip> <ssh-key>"
  exit 1
fi

# Extract the correct file prefix by removing '-signuture' from the path
FILENAME_PREFIX=$(basename "$TARGET_PATH" | sed 's/-signuture//g')

# Define the files to verify
SIG_FILE="${FILENAME_PREFIX}.sig"
TAR_FILE="${FILENAME_PREFIX}.tgz"

# Remote command to verify the GPG signature
REMOTE_COMMAND="cd taurus-binaries/$TARGET_PATH && gpg --verify $SIG_FILE $TAR_FILE"

# Execute the command on the EC2 instance
echo "Connecting to EC2 instance at $EC2_USER..."
echo "Verifying GPG signature for files: $SIG_FILE and $TAR_FILE in $TARGET_PATH..."

ssh -i "$SSH_KEY" "$EC2_USER" "$REMOTE_COMMAND"

# Check for errors
if [ $? -eq 0 ]; then
  echo "GPG signature verification succeeded for $TAR_FILE."
else
  echo "GPG signature verification failed for $TAR_FILE!"
  exit 2
fi
