#!/bin/bash
set -e

RANCHER_HOSTNAME="${RANCHER_HOSTNAME:-rancher.emelz.org}"
RANCHER_PASSWORD="${RANCHER_PASSWORD:-admin}"

echo "=== Installing Rancher ==="
echo "Hostname: $RANCHER_HOSTNAME"

# Install cert-manager
echo "Installing cert-manager..."
sudo k3s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml

# Wait for cert-manager to be ready
echo "Waiting for cert-manager..."
sudo k3s kubectl -n cert-manager rollout status deployment/cert-manager --timeout=180s

# Add Rancher Helm repo
echo "Adding Rancher Helm repository..."
if ! sudo su - root -c "helm repo list | grep -q rancher-stable"; then
    sudo su - root -c "helm repo add rancher-stable https://releases.rancher.com/server-charts/stable"
fi
sudo su - root -c "helm repo update"

# Create namespace
echo "Creating cattle-system namespace..."
sudo k3s kubectl create namespace cattle-system --dry-run=client -o yaml | sudo k3s kubectl apply -f -

# Install Rancher with external TLS
echo "Installing Rancher..."
sudo su - root -c "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && helm upgrade --install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=$RANCHER_HOSTNAME \
  --set bootstrapPassword=$RANCHER_PASSWORD \
  --set ingress.tls.source=secret \
  --set tls=external \
  --set 'extraEnv[0].name=CATTLE_TLS_MODE' \
  --set 'extraEnv[0].value=external'"

# Wait for Rancher to be ready
echo "Waiting for Rancher deployment..."
sudo k3s kubectl -n cattle-system rollout status deploy/rancher --timeout=300s

# Annotate Rancher ingress for Traefik
echo "Configuring Rancher ingress..."
sudo k3s kubectl -n cattle-system annotate ingress rancher kubernetes.io/ingress.class=traefik --overwrite

echo "✓ Rancher installed successfully"
echo ""
echo "Rancher will be accessible at: https://$RANCHER_HOSTNAME"
echo "Bootstrap password: $RANCHER_PASSWORD"
echo ""
echo "Note: Nginx must be configured to proxy to Rancher service (not Traefik)"

echo "=== Rancher installation complete ==="