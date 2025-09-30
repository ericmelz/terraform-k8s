# terraform-k8s

Infrastructure as Code for Kubernetes cluster with automated namespace management via GitOps.

## Overview

This project provisions and manages a complete Kubernetes stack on AWS with:
- **Infrastructure**: Terraform manages AWS resources (VPC, EC2, Route53, security groups)
- **Kubernetes**: K3s lightweight cluster with Rancher management UI
- **Networking**: Traefik ingress controller, Nginx reverse proxy with Let's Encrypt SSL
- **Remote Access**: Tailscale VPN for secure kubectl access from anywhere
- **GitOps**: Automated namespace deployment via GitHub Actions

## Quick Start

### Automated Full Stack Deployment

Deploy the entire stack from scratch with minimal intervention:

```bash
# Set your Tailscale auth key
export TAILSCALE_AUTH_KEY="tskey-client-YOUR-KEY"

# Deploy everything
cd terraform
terraform apply -auto-approve

# Get instance IP
INSTANCE_IP=$(terraform output -raw instance_public_ip)
cd ..

# Wait for SSH (30 retries, 10s each)
for i in {1..30}; do
  if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i ssh-keys/k8s-rancher-key.pem ubuntu@$INSTANCE_IP "echo ready" 2>/dev/null; then
    break
  fi
  sleep 10
done

# Install complete stack (K3s, Tailscale, Rancher, Hosty)
scp -o StrictHostKeyChecking=no -i ssh-keys/k8s-rancher-key.pem -r scripts ubuntu@$INSTANCE_IP:~/
ssh -o StrictHostKeyChecking=no -i ssh-keys/k8s-rancher-key.pem ubuntu@$INSTANCE_IP \
  "export TAILSCALE_AUTH_KEY='$TAILSCALE_AUTH_KEY' && sudo -E bash scripts/setup-all.sh"

# Update local kubeconfig
TAILSCALE_IP=$(ssh -i ssh-keys/k8s-rancher-key.pem ubuntu@$INSTANCE_IP "tailscale ip -4")
ssh -i ssh-keys/k8s-rancher-key.pem ubuntu@$INSTANCE_IP "sudo cat /etc/rancher/k3s/k3s.yaml" | \
  sed "s/127.0.0.1/$TAILSCALE_IP/" > ~/.kube/k3s-tailscale.yaml

# Test deployment
export KUBECONFIG=~/.kube/k3s-tailscale.yaml
kubectl get nodes
./scripts/test-hosty-routing.sh
```

### Teardown and Rebuild Cycle

To completely teardown and rebuild the stack:

```bash
# 1. Teardown
cd terraform
terraform destroy -auto-approve
cd ..

# 2. Rebuild (follow Automated Full Stack Deployment above)
```

**Note**: The `setup-all.sh` script now automatically:
- Installs K3s
- Connects to Tailscale (supports OAuth keys!)
- Installs Traefik and Rancher
- Configures Nginx with Let's Encrypt SSL
- Deploys Hosty to dev-weighter-net and weighter-org namespaces

### Manual Step-by-Step (Optional)

If you prefer manual control:

#### 1. Provision Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

#### 2. Install Kubernetes Stack

```bash
ssh -i ../ssh-keys/k8s-rancher-key.pem ubuntu@<instance-ip>
export TAILSCALE_AUTH_KEY="tskey-client-YOUR-KEY"
sudo -E bash scripts/setup-all.sh
```

#### 3. Configure GitOps

```bash
./scripts/setup-github-secrets.sh
```

#### 4. Deploy Namespaces

Add or modify namespace files in `k8s/namespaces/`, commit, and push. GitHub Actions automatically syncs them to the cluster.

## Project Structure

```
.
├── terraform/              # AWS infrastructure as code
│   ├── vpc.tf             # Network configuration
│   ├── ec2.tf             # Compute instance
│   ├── route53.tf         # DNS management
│   └── security-groups.tf # Firewall rules
├── scripts/               # Installation scripts
│   ├── setup-all.sh       # Master installation script
│   ├── install-k3s.sh     # Kubernetes cluster
│   ├── install-tailscale.sh # VPN access
│   └── install-rancher.sh # Management UI
├── k8s/
│   └── namespaces/        # GitOps-managed namespaces
└── .github/workflows/     # CI/CD automation
```

## Features

### Automated Namespace Management

Namespaces are managed in a GitOps style. Simply add YAML files to `k8s/namespaces/` and GitHub Actions automatically applies them:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: domain-tld
  labels:
    domain: domain.tld
    environment: production
    managed-by: gitops
```

See [k8s/namespaces/README.md](k8s/namespaces/README.md) for details.

### Remote kubectl Access

Access the cluster securely from your laptop via Tailscale:

```bash
export KUBECONFIG=~/.kube/k3s-tailscale.yaml
kubectl get nodes
kubectl get namespaces
```

### DNS Management

Route53 zones are managed by Terraform. Enable with:

```hcl
# terraform/terraform.tfvars
manage_dns = true
```

## Documentation

- [Installation Scripts](scripts/README.md) - Detailed script documentation
- [DNS Migration](README-DNS.md) - Route53 setup instructions
- [Namespace GitOps](k8s/namespaces/README.md) - Namespace management guide
- [CLAUDE.md](CLAUDE.md) - AI assistant context

## Access Points

After deployment:
- **Rancher UI**: https://rancher.emelz.org
- **Dev Applications**: https://dev.emelz.org
- **K3s API** (via Tailscale): https://100.x.x.x:6443

## Requirements

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- GitHub CLI (for GitOps setup)
- Tailscale account
- Domain with DNS access
