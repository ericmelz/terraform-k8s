#!/bin/bash
set -e

# Configuration variables
export RANCHER_HOSTNAME="${RANCHER_HOSTNAME:-rancher.emelz.org}"
export DEV_HOSTNAME="${DEV_HOSTNAME:-dev.emelz.org}"
export RANCHER_PASSWORD="${RANCHER_PASSWORD:-admin}"
export LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-eric@emelz.org}"

echo "=========================================="
echo "Kubernetes Stack Setup"
echo "=========================================="
echo "Rancher: https://$RANCHER_HOSTNAME"
echo "Dev:     https://$DEV_HOSTNAME"
echo "=========================================="
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to run script with error handling
run_script() {
    local script_name=$1
    local script_path="$SCRIPT_DIR/$script_name"

    echo ""
    echo ">>> Running $script_name..."
    if [ -f "$script_path" ]; then
        bash "$script_path"
    else
        echo "ERROR: Script not found: $script_path"
        exit 1
    fi
}

# Install components in order
run_script "install-k3s.sh"
run_script "install-tailscale.sh"
run_script "install-traefik.sh"
run_script "install-rancher.sh"
run_script "install-nginx.sh"
run_script "configure-nginx.sh"

echo ""
echo "=========================================="
echo "✓ Setup Complete!"
echo "=========================================="
echo ""
echo "Access points:"
echo "  Rancher UI:  https://$RANCHER_HOSTNAME"
echo "  Dev apps:    https://$DEV_HOSTNAME"
echo ""
echo "Rancher bootstrap password: $RANCHER_PASSWORD"
echo ""
echo "Next steps:"
echo "1. Visit https://$RANCHER_HOSTNAME to complete Rancher setup"
echo "2. Deploy demo applications to test the stack"
echo "=========================================="