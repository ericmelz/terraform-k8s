# Hosty Stack Deployment Script

## Overview

The `deploy-hosty-stack.sh` script is a master orchestration script that automates the complete deployment of the Hosty application stack from scratch.

## What It Does

This script performs the following steps in sequence:

1. **Checks Prerequisites** - Verifies that required tools are installed (terraform, kubectl, helm, docker, gh)
2. **Provisions AWS Infrastructure** - Runs Terraform to create VPC, EC2, security groups, etc.
3. **Waits for EC2 Instance** - Ensures the instance is accessible via SSH
4. **Installs Kubernetes Stack** - Deploys K3s, Tailscale, Rancher, Traefik, and nginx (optional)
5. **Verifies kubectl Access** - Confirms connection to the cluster via Tailscale
6. **Builds and Pushes Hosty Image** - Triggers GitHub Actions workflow to build multi-platform Docker image
7. **Deploys Hosty with Helm** - Installs Hosty to dev-weighter-net and weighter-org namespaces
8. **Sets up Ingress Controller** - Configures nginx or Traefik for host-based routing
9. **Tests Multi-Domain Routing** - Runs automated tests to verify host headers

## Usage

### Full Deployment (from scratch)

```bash
# Set Tailscale auth key
export TAILSCALE_AUTH_KEY="tskey-auth-YOUR-KEY"

# Run the master script
./scripts/deploy-hosty-stack.sh
```

The script is interactive and will prompt you at key decision points:
- Whether to apply Terraform changes
- Whether to install the Kubernetes stack
- Whether to trigger Docker image build
- Which ingress controller to use

### Partial Deployment (existing infrastructure)

If you already have infrastructure set up, you can skip steps by answering "n" to the prompts:

```bash
# Skip Terraform, K8s installation, just deploy Hosty
./scripts/deploy-hosty-stack.sh
```

## Prerequisites

The script requires the following tools to be installed:

- **terraform** - Infrastructure provisioning
- **kubectl** - Kubernetes cluster management
- **helm** - Kubernetes package manager
- **docker** - For verifying image availability
- **gh** - GitHub CLI for triggering workflows
- **Tailscale** - VPN for cluster access (running and connected)

## Environment Variables

### Required

- `TAILSCALE_AUTH_KEY` - Auth key for Tailscale VPN (only needed if installing K8s stack)

### Optional

- `KUBECONFIG` - Path to kubeconfig file (default: `/Users/ericmelz/.kube/k3s-tailscale.yaml`)

## What Gets Deployed

### Infrastructure (Terraform)
- VPC with public/private subnets
- EC2 instance (t3.medium or larger)
- Security groups for HTTP/HTTPS/SSH/K8s
- Route53 DNS zones (if manage_dns = true)

### Kubernetes Stack
- K3s lightweight Kubernetes
- Tailscale for remote access
- Rancher management UI (optional)
- Traefik or nginx ingress controller

### Hosty Application
- Hosty FastAPI application (multi-platform Docker image)
- Deployed to two namespaces:
  - `dev-weighter-net` (release: hosty-dev)
  - `weighter-org` (release: hosty-prod)
- Kubernetes resources:
  - Deployment (1 replica per namespace)
  - Service (ClusterIP on port 8000)
  - Ingress/IngressRoute (host-based routing)

### Ingress Configuration
- **dev.weighter.net** → hosty-dev service
- **weighter.org** → hosty-prod service
- **www.weighter.org** → hosty-prod service

## Post-Deployment

After the script completes:

1. **Configure DNS**: Point your domains to the ingress controller external IP
   ```bash
   # Get the external IP
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   # or for Traefik
   kubectl get svc -n traefik traefik
   ```

2. **Update Route53 or your DNS provider**:
   ```
   dev.weighter.net    A    <EXTERNAL_IP>
   weighter.org        A    <EXTERNAL_IP>
   www.weighter.org    A    <EXTERNAL_IP>
   ```

3. **Wait for SSL certificates** (if using cert-manager/Let's Encrypt)

4. **Test in browser**:
   - https://dev.weighter.net
   - https://weighter.org
   - https://www.weighter.org

## Troubleshooting

### Script fails at Terraform step
- Ensure AWS credentials are configured: `aws configure`
- Check Terraform state: `cd terraform && terraform state list`

### Cannot connect to cluster
- Verify Tailscale is running: `tailscale status`
- Check kubeconfig path: `echo $KUBECONFIG`
- Test connection: `kubectl get nodes`

### Docker image build fails
- Check GitHub Actions: `gh run list --workflow=build-hosty.yaml`
- View logs: `gh run view <run-id> --log`

### Pods not starting
- Check pod status: `kubectl get pods -n dev-weighter-net -o wide`
- View logs: `kubectl logs -n dev-weighter-net <pod-name>`
- Describe pod: `kubectl describe pod -n dev-weighter-net <pod-name>`

### Tests fail
- Ensure pods are running: `kubectl get pods -A`
- Check services: `kubectl get svc -n dev-weighter-net`
- Manually test: `kubectl port-forward -n dev-weighter-net svc/hosty-dev 8000:8000`

## Idempotency

The script is designed to be idempotent:
- Terraform will only apply changes if needed
- Helm uses `upgrade --install` (creates or updates)
- Ingress resources can be reapplied safely

You can run the script multiple times without causing issues.

## Script Location

`scripts/deploy-hosty-stack.sh`

## Related Scripts

- `scripts/setup-all.sh` - K8s stack installation (called by this script)
- `scripts/setup-nginx-ingress.sh` - nginx ingress setup
- `scripts/setup-traefik-ingress.sh` - Traefik ingress setup
- `scripts/test-hosty-routing.sh` - Routing tests
- `scripts/setup-github-secrets.sh` - GitOps configuration