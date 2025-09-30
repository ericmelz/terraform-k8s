#!/bin/bash
set -e

# Script to generate and encrypt configuration files for Hosty
# Usage:
#   export NON_SECRET_CONF_FILE_VAR="dev-non-secret-conf-value"
#   export SECRET_CONF_FILE_VAR="dev-secret-conf-value"
#   export GPG_PASSPHRASE="your-passphrase"
#   ./generate-config.sh dev

if [ $# -ne 1 ]; then
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    echo ""
    echo "Required environment variables:"
    echo "  NON_SECRET_CONF_FILE_VAR - non-secret configuration value"
    echo "  SECRET_CONF_FILE_VAR - secret configuration value"
    echo "  GPG_PASSPHRASE - passphrase for encryption"
    exit 1
fi

ENV=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_FILE="$APP_DIR/config-templates/.env.template"
OUTPUT_DIR="$APP_DIR/app-conf/$ENV"
OUTPUT_FILE="$OUTPUT_DIR/.env"
ENCRYPTED_FILE="$OUTPUT_DIR/.env.gpg"

# Validate required environment variables
if [ -z "$NON_SECRET_CONF_FILE_VAR" ]; then
    echo "ERROR: NON_SECRET_CONF_FILE_VAR is not set"
    exit 1
fi

if [ -z "$SECRET_CONF_FILE_VAR" ]; then
    echo "ERROR: SECRET_CONF_FILE_VAR is not set"
    exit 1
fi

if [ -z "$GPG_PASSPHRASE" ]; then
    echo "ERROR: GPG_PASSPHRASE is not set"
    exit 1
fi

echo "Generating configuration for environment: $ENV"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Generate configuration file from template
echo "Generating $OUTPUT_FILE..."
cat "$TEMPLATE_FILE" | \
    sed "s/placeholder-non-secret-value/$NON_SECRET_CONF_FILE_VAR/" | \
    sed "s/placeholder-secret-value/$SECRET_CONF_FILE_VAR/" > "$OUTPUT_FILE"

echo "Configuration file generated: $OUTPUT_FILE"

# Encrypt the configuration file
echo "Encrypting configuration..."
gpg --batch --yes --passphrase "$GPG_PASSPHRASE" \
    --symmetric --cipher-algo AES256 \
    --output "$ENCRYPTED_FILE" \
    "$OUTPUT_FILE"

echo "Encrypted configuration saved: $ENCRYPTED_FILE"

# Remove unencrypted file for security
rm "$OUTPUT_FILE"
echo "Removed unencrypted file: $OUTPUT_FILE"

echo ""
echo "✓ Configuration generated and encrypted successfully"
echo "Encrypted file: $ENCRYPTED_FILE"
echo ""
echo "To decrypt manually:"
echo "  gpg --batch --passphrase 'YOUR_PASSPHRASE' --decrypt $ENCRYPTED_FILE"