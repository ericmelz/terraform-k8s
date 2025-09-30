#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
export KUBECONFIG=${KUBECONFIG:-/Users/ericmelz/.kube/k3s-tailscale.yaml}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Hosty Stack Deployment"
echo "=========================================="
echo ""

# Function to print section headers
section() {
    echo ""
    echo -e "${BLUE}>>> $1${NC}"
    echo ""
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${YELLOW}Warning: $1 is not installed${NC}"
        return 1
    fi
    return 0
}

# Check prerequisites
section "Checking Prerequisites"

MISSING_DEPS=false
for cmd in terraform kubectl helm docker gh; do
    if check_command $cmd; then
        echo "✓ $cmd is installed"
    else
        MISSING_DEPS=true
    fi
done

if [ "$MISSING_DEPS" = true ]; then
    echo ""
    echo "Please install missing dependencies before continuing."
    exit 1
fi

# Step 1: Terraform Infrastructure
section "Step 1: Provisioning AWS Infrastructure with Terraform"

cd "$PROJECT_ROOT/terraform"

if [ ! -f "terraform.tfstate" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

echo "Planning Terraform changes..."
terraform plan -out=tfplan

read -p "Apply Terraform plan? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply tfplan
    rm tfplan
    echo -e "${GREEN}✓ Infrastructure provisioned${NC}"
else
    echo "Skipping Terraform apply"
    rm tfplan
fi

cd "$PROJECT_ROOT"

# Step 2: Wait for SSH access
section "Step 2: Waiting for EC2 Instance"

INSTANCE_IP=$(cd terraform && terraform output -raw instance_public_ip 2>/dev/null || echo "")

if [ -z "$INSTANCE_IP" ]; then
    echo "Could not get instance IP from Terraform. Skipping infrastructure setup."
    echo "If you already have the infrastructure set up, continue to application deployment."
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "Instance IP: $INSTANCE_IP"
    echo "Waiting for SSH to become available..."

    MAX_RETRIES=30
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ssh-keys/k8s-rancher-key.pem ubuntu@$INSTANCE_IP "echo 'SSH ready'" 2>/dev/null; then
            echo -e "${GREEN}✓ SSH is ready${NC}"
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "Retry $RETRY_COUNT/$MAX_RETRIES..."
        sleep 10
    done

    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo "SSH did not become available in time"
        exit 1
    fi
fi

# Step 3: Install K8s stack (if needed)
section "Step 3: Kubernetes Stack Installation"

echo "Do you need to install the Kubernetes stack (K3s, Tailscale, etc)?"
read -p "Install? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -z "$TAILSCALE_AUTH_KEY" ]; then
        echo "Please set TAILSCALE_AUTH_KEY environment variable"
        read -p "Enter Tailscale auth key: " TAILSCALE_AUTH_KEY
        export TAILSCALE_AUTH_KEY
    fi

    echo "Installing Kubernetes stack on $INSTANCE_IP..."
    scp -i ssh-keys/k8s-rancher-key.pem -r scripts ubuntu@$INSTANCE_IP:~/
    ssh -i ssh-keys/k8s-rancher-key.pem ubuntu@$INSTANCE_IP "export TAILSCALE_AUTH_KEY='$TAILSCALE_AUTH_KEY' && sudo -E bash scripts/setup-all.sh"

    echo -e "${GREEN}✓ Kubernetes stack installed${NC}"
else
    echo "Skipping Kubernetes stack installation"
fi

# Step 4: Verify kubectl access
section "Step 4: Verifying kubectl Access"

if kubectl get nodes &>/dev/null; then
    echo -e "${GREEN}✓ kubectl is configured and can access the cluster${NC}"
    kubectl get nodes
else
    echo "kubectl cannot access the cluster. Please ensure:"
    echo "  1. Tailscale is connected"
    echo "  2. KUBECONFIG is set correctly: $KUBECONFIG"
    echo "  3. The kubeconfig file exists and is valid"
    exit 1
fi

# Step 5: Build and push Hosty Docker image
section "Step 5: Building and Pushing Hosty Docker Image"

read -p "Trigger GitHub Actions to build Hosty image? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$PROJECT_ROOT"
    echo "Triggering build-hosty workflow..."
    gh workflow run build-hosty.yaml

    echo "Waiting for workflow to start..."
    sleep 5

    echo "Watching workflow progress..."
    WORKFLOW_ID=$(gh run list --workflow=build-hosty.yaml --limit 1 --json databaseId --jq '.[0].databaseId')
    gh run watch $WORKFLOW_ID --exit-status

    echo -e "${GREEN}✓ Hosty image built and pushed${NC}"
else
    echo "Skipping Docker build. Make sure the image exists at ghcr.io/ericmelz/hosty:latest"
fi

# Step 6: Deploy Hosty with Helm
section "Step 6: Deploying Hosty to Kubernetes"

cd "$PROJECT_ROOT"

echo "Deploying Hosty to dev-weighter-net namespace..."
helm upgrade --install hosty-dev ./apps/hosty/helm/hosty \
    --namespace dev-weighter-net \
    --create-namespace \
    --wait

echo "Deploying Hosty to weighter-org namespace..."
helm upgrade --install hosty-prod ./apps/hosty/helm/hosty \
    --namespace weighter-org \
    --create-namespace \
    --wait

echo -e "${GREEN}✓ Hosty deployed to both namespaces${NC}"

# Step 7: Setup Ingress Controller
section "Step 7: Setting up Ingress Controller"

echo "Which ingress controller do you want to use?"
echo "  1) nginx (recommended)"
echo "  2) Traefik"
echo "  3) Skip (already installed)"
read -p "Choose [1-3]: " -n 1 -r
echo

case $REPLY in
    1)
        echo "Installing nginx ingress controller..."
        bash "$SCRIPT_DIR/setup-nginx-ingress.sh"
        echo -e "${GREEN}✓ nginx ingress configured${NC}"
        ;;
    2)
        echo "Installing Traefik ingress controller..."
        bash "$SCRIPT_DIR/setup-traefik-ingress.sh"
        echo -e "${GREEN}✓ Traefik ingress configured${NC}"
        ;;
    *)
        echo "Skipping ingress installation"
        ;;
esac

# Step 8: Test Hosty Routing
section "Step 8: Testing Hosty Multi-Domain Routing"

echo "Running routing tests..."
bash "$SCRIPT_DIR/test-hosty-routing.sh"

# Final Summary
section "Deployment Complete!"

echo -e "${GREEN}✓ All steps completed successfully!${NC}"
echo ""
echo "Deployed applications:"
kubectl get pods -n dev-weighter-net
echo ""
kubectl get pods -n weighter-org
echo ""
echo "Access points (once DNS is configured):"
echo "  - https://dev.weighter.net"
echo "  - https://weighter.org"
echo "  - https://www.weighter.org"
echo ""
echo "Next steps:"
echo "  1. Configure DNS to point to the ingress controller external IP"
echo "  2. Verify HTTPS certificates are issued"
echo "  3. Test the applications in your browser"
echo ""
echo "=========================================="