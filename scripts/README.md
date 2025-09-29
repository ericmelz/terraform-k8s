# Installation Scripts

Automated installation scripts for the Kubernetes stack with Rancher, Traefik, and Nginx.

## Scripts Overview

### Individual Component Scripts

1. **`install-k3s.sh`** - Install K3s (lightweight Kubernetes)
   - Disables default Traefik
   - Waits for cluster to be ready
   - Verifies installation

2. **`install-traefik.sh`** - Install Traefik ingress controller
   - Installs CRDs and RBAC
   - Deploys Traefik with NodePort (30080)
   - Configures proper permissions

3. **`install-rancher.sh`** - Install Rancher management UI
   - Installs cert-manager
   - Deploys Rancher via Helm
   - Configures for external TLS termination
   - Environment variables:
     - `RANCHER_HOSTNAME` (default: rancher.emelz.org)
     - `RANCHER_PASSWORD` (default: admin)

4. **`install-nginx.sh`** - Install Nginx and Certbot
   - Installs packages
   - Enables service

5. **`configure-nginx.sh`** - Configure Nginx with SSL and proxying
   - Obtains Let's Encrypt certificates
   - Configures reverse proxy to Rancher and Traefik
   - Sets up HTTPS redirects
   - Environment variables:
     - `RANCHER_HOSTNAME` (default: rancher.emelz.org)
     - `DEV_HOSTNAME` (default: dev.emelz.org)
     - `LETSENCRYPT_EMAIL` (default: eric@emelz.org)

### Master Script

**`setup-all.sh`** - Run all installation scripts in order
- Executes all components sequentially
- Handles errors and provides progress feedback
- Customizable via environment variables

## Usage

### Quick Start (Automated)

```bash
# SSH to the instance
ssh -i ../ssh-keys/k8s-rancher-key.pem ubuntu@<instance-ip>

# Clone or copy scripts to the instance
# Then run:
sudo bash scripts/setup-all.sh
```

### Manual Installation (Step-by-Step)

```bash
# Install components individually
sudo bash scripts/install-k3s.sh
sudo bash scripts/install-traefik.sh
sudo bash scripts/install-rancher.sh
sudo bash scripts/install-nginx.sh
sudo bash scripts/configure-nginx.sh
```

### Custom Configuration

```bash
# Set environment variables before running
export RANCHER_HOSTNAME="rancher.yourdomain.com"
export DEV_HOSTNAME="dev.yourdomain.com"
export RANCHER_PASSWORD="your-secure-password"
export LETSENCRYPT_EMAIL="your-email@example.com"

sudo -E bash scripts/setup-all.sh
```

## Prerequisites

- Ubuntu 22.04 LTS
- Docker, kubectl, and helm installed (handled by Terraform user_data)
- DNS records for rancher and dev subdomains pointing to instance IP
- Ports 80, 443, 6443 open in security groups

## What Gets Installed

### K3s Cluster
- Single-node Kubernetes cluster
- Version: Latest stable
- Traefik disabled (installed separately)

### Traefik
- Version: v2.10
- NodePort service on port 30080
- Dashboard on port 8080
- Handles ingress for dev applications

### Rancher
- Version: Latest stable (v2.9.x)
- Configured for external TLS termination
- Bootstrap password configurable
- Accessible via Nginx proxy

### Nginx
- Reverse proxy on host
- TLS termination with Let's Encrypt
- Proxies to:
  - Rancher service (direct to ClusterIP)
  - Traefik (via NodePort for dev apps)

## Architecture

```
Internet
  ↓
Nginx (Host, Port 443 - TLS Termination)
  ├→ rancher.emelz.org → Rancher Service (K8s ClusterIP)
  └→ dev.emelz.org → Traefik (NodePort 30080) → K8s Services
```

## Troubleshooting

### Check Installation Logs

```bash
# User data log (initial setup)
sudo tail -f /var/log/user-data.log

# K3s logs
sudo journalctl -u k3s -f

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Check pods
sudo k3s kubectl get pods -A
```

### Verify Services

```bash
# Check K3s
sudo k3s kubectl get nodes

# Check Traefik
sudo k3s kubectl -n traefik get pods

# Check Rancher
sudo k3s kubectl -n cattle-system get pods

# Check Nginx
sudo systemctl status nginx

# Test Rancher service
curl -H "Host: rancher.emelz.org" http://$(sudo k3s kubectl -n cattle-system get svc rancher -o jsonpath='{.spec.clusterIP}')
```

### Common Issues

1. **Rancher redirect loop**
   - Ensure Nginx is proxying directly to Rancher ClusterIP, not through Traefik
   - Verify X-Forwarded-Proto headers are set

2. **Let's Encrypt rate limits**
   - Use staging environment for testing: `--staging` flag in certbot
   - Production allows 5 failures per hour

3. **DNS not resolving**
   - Verify DNS records are propagated: `dig rancher.emelz.org`
   - Wait 5-15 minutes after creating records

## Rerunning Scripts

Scripts are idempotent where possible, but some may fail if resources already exist. To reinstall:

```bash
# Uninstall K3s
sudo /usr/local/bin/k3s-uninstall.sh

# Remove Nginx config
sudo rm /etc/nginx/sites-enabled/k8s-proxy

# Then rerun setup scripts
```

## Future Enhancements

- [ ] Add Tailscale installation script
- [ ] Add demo app deployment script
- [ ] Add backup/restore scripts
- [ ] Add monitoring setup (Prometheus/Grafana)
- [ ] Make scripts fully idempotent