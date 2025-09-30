#!/bin/bash
set -e

echo "=== Deploying Hosty Application ==="

# Wait for Tailscale to be ready
echo "Waiting for Tailscale IP..."
TAILSCALE_IP=$(tailscale ip -4)
echo "Tailscale IP: $TAILSCALE_IP"

# Get kubeconfig from local K3s
echo "Preparing kubeconfig..."
export KUBECONFIG=/tmp/k3s-local.yaml
sudo cat /etc/rancher/k3s/k3s.yaml > $KUBECONFIG
sudo chmod 644 $KUBECONFIG

# Wait for K3s to be ready
echo "Waiting for Kubernetes to be ready..."
timeout=60
while [ $timeout -gt 0 ]; do
    if kubectl get nodes &>/dev/null; then
        break
    fi
    sleep 2
    timeout=$((timeout - 2))
done

if [ $timeout -le 0 ]; then
    echo "ERROR: Kubernetes is not ready"
    exit 1
fi

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Navigate to the apps directory
cd /home/ubuntu

# Clone the repository if not already present
if [ ! -d "terraform-k8s" ]; then
    echo "Cloning repository..."
    git clone https://github.com/ericmelz/terraform-k8s.git
fi

cd terraform-k8s

# Pull latest changes
echo "Pulling latest changes..."
git pull

# Deploy Hosty to dev namespace with dev-specific values
echo "Deploying Hosty to dev-weighter-net namespace..."
helm upgrade --install hosty-dev ./apps/hosty/helm/hosty \
    --namespace dev-weighter-net \
    --create-namespace \
    --values ./apps/hosty/helm/hosty/values-dev.yaml \
    --wait

# Deploy Hosty to prod namespace with prod-specific values
echo "Deploying Hosty to weighter-org namespace..."
helm upgrade --install hosty-prod ./apps/hosty/helm/hosty \
    --namespace weighter-org \
    --create-namespace \
    --values ./apps/hosty/helm/hosty/values-prod.yaml \
    --wait

echo "✓ Hosty deployed successfully"
echo ""
echo "Deployed releases:"
helm list -n dev-weighter-net
helm list -n weighter-org
echo ""
echo "=== Hosty deployment complete ==="
echo ""
echo "Hosty is now accessible via port-forward or ingress:"
echo "  kubectl port-forward -n dev-weighter-net svc/hosty-dev 8000:8000"
echo "  kubectl port-forward -n weighter-org svc/hosty-prod 8000:8000"