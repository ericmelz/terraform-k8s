#!/bin/bash
set -e

echo "=== GitHub Secrets Setup for GitOps ==="
echo ""
echo "This script will help you configure GitHub secrets for the namespace sync workflow."
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "ERROR: GitHub CLI (gh) is not installed."
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if logged in
if ! gh auth status &> /dev/null; then
    echo "Please log in to GitHub CLI first:"
    echo "  gh auth login"
    exit 1
fi

echo "Step 1: Setting up KUBECONFIG secret"
echo "---------------------------------------"
echo "This will encode your Tailscale kubeconfig and store it as a GitHub secret."
echo ""

KUBECONFIG_PATH="$HOME/.kube/k3s-tailscale.yaml"

if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "ERROR: Kubeconfig not found at $KUBECONFIG_PATH"
    echo "Make sure you've set up Tailscale access to your cluster first."
    exit 1
fi

# Encode kubeconfig to base64
KUBECONFIG_BASE64=$(base64 < "$KUBECONFIG_PATH")

# Set the secret
echo "Setting KUBECONFIG secret..."
echo "$KUBECONFIG_BASE64" | gh secret set KUBECONFIG

echo "✓ KUBECONFIG secret set successfully"
echo ""

echo "Step 2: Setting up Tailscale OAuth credentials"
echo "-----------------------------------------------"
echo "You need to create a Tailscale OAuth client to allow GitHub Actions to connect."
echo ""
echo "1. Go to: https://login.tailscale.com/admin/settings/oauth"
echo "2. Click 'Generate OAuth Client'"
echo "3. Add tag: ci"
echo "4. Copy the Client ID and Client Secret"
echo ""

read -p "Enter Tailscale OAuth Client ID: " TAILSCALE_CLIENT_ID
read -sp "Enter Tailscale OAuth Client Secret: " TAILSCALE_CLIENT_SECRET
echo ""

if [ -z "$TAILSCALE_CLIENT_ID" ] || [ -z "$TAILSCALE_CLIENT_SECRET" ]; then
    echo "ERROR: Both Client ID and Client Secret are required"
    exit 1
fi

echo "Setting Tailscale secrets..."
echo "$TAILSCALE_CLIENT_ID" | gh secret set TAILSCALE_OAUTH_CLIENT_ID
echo "$TAILSCALE_CLIENT_SECRET" | gh secret set TAILSCALE_OAUTH_CLIENT_SECRET

echo "✓ Tailscale secrets set successfully"
echo ""

echo "=== Setup Complete! ==="
echo ""
echo "GitHub secrets configured:"
echo "  - KUBECONFIG"
echo "  - TAILSCALE_OAUTH_CLIENT_ID"
echo "  - TAILSCALE_OAUTH_CLIENT_SECRET"
echo ""
echo "You can now push changes to k8s/namespaces/ and GitHub Actions will sync them to your cluster."
echo ""
echo "To verify:"
echo "  gh secret list"