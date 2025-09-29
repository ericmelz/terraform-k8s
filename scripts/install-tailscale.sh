#!/bin/bash
set -e

echo "=== Installing Tailscale ==="

# Check if Tailscale auth key is provided
if [ -z "$TAILSCALE_AUTH_KEY" ]; then
    echo "ERROR: TAILSCALE_AUTH_KEY environment variable is required"
    echo "Please set it before running this script:"
    echo "  export TAILSCALE_AUTH_KEY='tskey-auth-...'"
    echo ""
    echo "You can generate an auth key at: https://login.tailscale.com/admin/settings/keys"
    exit 1
fi

# Install Tailscale
echo "Installing Tailscale package..."
curl -fsSL https://tailscale.com/install.sh | sh

# Start and authenticate Tailscale
echo "Connecting to Tailscale network..."
sudo tailscale up --auth-key="$TAILSCALE_AUTH_KEY" --accept-routes

# Get Tailscale IP
echo "Getting Tailscale IP address..."
sleep 5
TAILSCALE_IP=$(tailscale ip -4)
echo "Tailscale IP: $TAILSCALE_IP"

# Configure K3s to listen on Tailscale interface
echo "Configuring K3s to be accessible over Tailscale..."

# Check if K3s is already installed
if ! command -v k3s &> /dev/null; then
    echo "WARNING: K3s not found. Please run install-k3s.sh first."
    exit 1
fi

# Create K3s config directory if it doesn't exist
sudo mkdir -p /etc/rancher/k3s

# Create or update K3s config file
echo "Creating K3s configuration..."
sudo tee /etc/rancher/k3s/config.yaml > /dev/null <<EOF
disable:
  - traefik
tls-san:
  - $TAILSCALE_IP
  - $(hostname)
  - $(hostname -f)
EOF

# Restart K3s to apply configuration
echo "Restarting K3s..."
sudo systemctl restart k3s
sleep 10

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
timeout=60
while [ $timeout -gt 0 ]; do
    if sudo k3s kubectl get nodes &>/dev/null; then
        break
    fi
    sleep 2
    timeout=$((timeout - 2))
done

if [ $timeout -le 0 ]; then
    echo "ERROR: K3s failed to start"
    echo "Check logs with: sudo journalctl -xeu k3s.service"
    exit 1
fi

echo "✓ Tailscale installed successfully"
echo ""
echo "Tailscale IP: $TAILSCALE_IP"
echo "K3s API Server: https://$TAILSCALE_IP:6443"
echo ""
echo "=== Tailscale installation complete ==="
echo ""
echo "To access the cluster from your laptop:"
echo "1. Install Tailscale on your laptop: https://tailscale.com/download"
echo "2. Join the same tailnet"
echo "3. Copy the kubeconfig:"
echo "   scp -i ../ssh-keys/k8s-rancher-key.pem ubuntu@$TAILSCALE_IP:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s-tailscale.yaml"
echo "4. Edit ~/.kube/k3s-tailscale.yaml and replace 'server: https://127.0.0.1:6443' with 'server: https://$TAILSCALE_IP:6443'"
echo "5. Use kubectl:"
echo "   export KUBECONFIG=~/.kube/k3s-tailscale.yaml"
echo "   kubectl get nodes"