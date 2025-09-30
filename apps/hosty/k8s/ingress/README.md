# Hosty Ingress Configuration

This directory contains ingress configurations for routing traffic to the Hosty application based on the host header.

## Architecture

- **dev.weighter.net** → `hosty-dev` service in `dev-weighter-net` namespace
- **weighter.org** / **www.weighter.org** → `hosty-prod` service in `weighter-org` namespace

## Setup Options

You can use either **nginx Ingress Controller** or **Traefik**:

### Option 1: nginx Ingress Controller (Recommended)

```bash
# Install nginx ingress controller and apply ingress resources
./scripts/setup-nginx-ingress.sh
```

This will:
1. Install nginx Ingress Controller
2. Create Ingress resources for both dev and prod
3. Set up TLS/SSL with cert-manager (if installed)

### Option 2: Traefik

```bash
# Install Traefik and apply IngressRoute resources
./scripts/setup-traefik-ingress.sh
```

This will:
1. Install Traefik via Helm
2. Create IngressRoute resources for both dev and prod
3. Set up HTTP to HTTPS redirect
4. Configure TLS with Let's Encrypt

## Manual Deployment

If you prefer to deploy manually:

### nginx Ingress

```bash
export KUBECONFIG=/Users/ericmelz/.kube/k3s-tailscale.yaml

# Install nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/cloud/deploy.yaml

# Apply ingress resources
kubectl apply -f apps/hosty/k8s/ingress/nginx-ingress-dev.yaml
kubectl apply -f apps/hosty/k8s/ingress/nginx-ingress-prod.yaml
```

### Traefik

```bash
export KUBECONFIG=/Users/ericmelz/.kube/k3s-tailscale.yaml

# Install Traefik
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik --namespace traefik --create-namespace

# Apply IngressRoute resources
kubectl apply -f apps/hosty/k8s/ingress/traefik-ingressroute-dev.yaml
kubectl apply -f apps/hosty/k8s/ingress/traefik-ingressroute-prod.yaml
```

## DNS Configuration

After deploying the ingress controller, get the external IP:

```bash
# For nginx
kubectl get svc -n ingress-nginx ingress-nginx-controller

# For Traefik
kubectl get svc -n traefik traefik
```

Then configure your DNS records in Route53 or your DNS provider:

```
dev.weighter.net    A    <EXTERNAL_IP>
weighter.org        A    <EXTERNAL_IP>
www.weighter.org    A    <EXTERNAL_IP>
```

## Verification

Test that the routing works correctly:

```bash
# Test dev environment
curl https://dev.weighter.net
# Expected: {"host": "dev.weighter.net", "message": "I'm being hit from dev.weighter.net!"}

# Test prod environment
curl https://weighter.org
# Expected: {"host": "weighter.org", "message": "I'm being hit from weighter.org!"}

# Test with www subdomain
curl https://www.weighter.org
# Expected: {"host": "www.weighter.org", "message": "I'm being hit from www.weighter.org!"}
```

## Ingress Files

- `nginx-ingress-dev.yaml` - nginx Ingress for dev.weighter.net
- `nginx-ingress-prod.yaml` - nginx Ingress for weighter.org and www.weighter.org
- `traefik-ingressroute-dev.yaml` - Traefik IngressRoute for dev.weighter.net
- `traefik-ingressroute-prod.yaml` - Traefik IngressRoute for weighter.org and www.weighter.org

## TLS/SSL Certificates

Both configurations include TLS support:

- **nginx**: Uses cert-manager with Let's Encrypt (requires cert-manager to be installed)
- **Traefik**: Uses built-in Let's Encrypt certificate resolver

To install cert-manager for nginx:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

## Troubleshooting

Check ingress status:

```bash
# nginx
kubectl get ingress -n dev-weighter-net
kubectl get ingress -n weighter-org
kubectl describe ingress hosty-dev -n dev-weighter-net

# Traefik
kubectl get ingressroute -n dev-weighter-net
kubectl get ingressroute -n weighter-org
kubectl describe ingressroute hosty-dev -n dev-weighter-net
```

Check ingress controller logs:

```bash
# nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik
```