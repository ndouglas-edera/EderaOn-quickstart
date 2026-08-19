#!/usr/bin/env bash

set -euo pipefail

TARGET_DIR="/var/lib/edera/protect"
LICENSE_FILE="${TARGET_DIR}/license.key"

# Regex matching: 5 blocks of 6 hex/alphanumeric chars + 1 block starting with 'V' and digits
LICENSE_REGEX="^([A-Z0-9]{6}-){5}V[0-9]+$"

echo "----------------------------------------------------"
echo "Please retrieve your license key from https://on.edera.dev"
echo "----------------------------------------------------"

read -rp "Enter your Edera license key: " USER_KEY

# Trim leading/trailing whitespace
USER_KEY=$(echo "$USER_KEY" | xargs)

if [[ ! "$USER_KEY" =~ $LICENSE_REGEX ]]; then
    echo "Error: Invalid license key format." >&2
    echo "Expected format: XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-VX" >&2
    exit 1
fi

echo "License key format validated successfully."

# Ensure target directory exists (requires appropriate permissions/sudo if in /var)
if ! mkdir -p "$TARGET_DIR" 2>/dev/null; then
    echo "Notice: Elevating permissions to write to $TARGET_DIR..."
    sudo mkdir -p "$TARGET_DIR"
    echo "$USER_KEY" | sudo tee "$LICENSE_FILE" > /dev/null
else
    echo "$USER_KEY" > "$LICENSE_FILE"
fi

echo "License key saved to $LICENSE_FILE"
