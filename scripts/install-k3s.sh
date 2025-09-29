#!/bin/bash
set -e

echo "=== Installing K3s ==="

# Install K3s without Traefik (we'll install it separately)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
sleep 10

# Verify installation
if sudo k3s kubectl get nodes | grep -q "Ready"; then
    echo "✓ K3s installed successfully"
    sudo k3s kubectl get nodes
else
    echo "✗ K3s installation failed"
    exit 1
fi

echo "=== K3s installation complete ==="