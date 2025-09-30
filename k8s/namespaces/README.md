# Kubernetes Namespaces (GitOps)

This directory contains Kubernetes namespace manifests that are automatically synced to the cluster via GitHub Actions.

## Overview

Namespaces are managed in a GitOps style:
1. Add or modify YAML files in this directory
2. Commit and push to the `main` branch
3. GitHub Actions automatically applies changes to the cluster via Tailscale

## Namespace Structure

Each namespace should have its own YAML file with the following structure:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: domain-tld
  labels:
    domain: domain.tld
    environment: production|development|staging
    managed-by: gitops
```

## Current Namespaces

- **emelz-org** - Production namespace for emelz.org domain
- **weighter-net** - Production namespace for weighter.net domain
- **weighter-org** - Production namespace for weighter.org domain
- **dev-weighter-net** - Development namespace for weighter.net domain

## Adding a New Namespace

1. Create a new YAML file in this directory:
   ```bash
   cat > k8s/namespaces/new-domain-com.yaml <<EOF
   apiVersion: v1
   kind: Namespace
   metadata:
     name: new-domain-com
     labels:
       domain: new-domain.com
       environment: production
       managed-by: gitops
   EOF
   ```

2. Commit and push:
   ```bash
   git add k8s/namespaces/new-domain-com.yaml
   git commit -m "Add new-domain-com namespace"
   git push
   ```

3. GitHub Actions will automatically create the namespace in the cluster.

## Manual Deployment

You can also manually apply namespace changes using kubectl over Tailscale:

```bash
export KUBECONFIG=~/.kube/k3s-tailscale.yaml
kubectl apply -f k8s/namespaces/
```

## Viewing Namespaces

List all GitOps-managed namespaces:

```bash
kubectl get namespaces -l managed-by=gitops
```

View detailed information about a specific namespace:

```bash
kubectl describe namespace emelz-org
```

## GitHub Actions Workflow

The sync workflow (`.github/workflows/sync-namespaces.yaml`) runs when:
- Changes are pushed to `k8s/namespaces/**` on the `main` branch
- Manually triggered via the Actions tab

The workflow:
1. Connects to the cluster via Tailscale
2. Applies all namespace manifests
3. Lists the current GitOps-managed namespaces

## Setup Requirements

Before the GitOps workflow can run, you need to configure GitHub secrets:

```bash
./scripts/setup-github-secrets.sh
```

This sets up:
- `KUBECONFIG` - Base64-encoded kubeconfig for Tailscale access
- `TAILSCALE_OAUTH_CLIENT_ID` - Tailscale OAuth client ID
- `TAILSCALE_OAUTH_CLIENT_SECRET` - Tailscale OAuth client secret

## Troubleshooting

### Workflow fails with "connection refused"
- Verify Tailscale OAuth credentials are correct
- Check that the cluster is accessible via Tailscale
- Ensure the kubeconfig has the correct Tailscale IP

### Namespace not created
- Check GitHub Actions logs for errors
- Verify the YAML syntax is correct
- Ensure the namespace name follows Kubernetes naming conventions (lowercase, hyphens only)

### Manual verification
```bash
# Check if namespace exists
kubectl get namespace <namespace-name>

# View recent events
kubectl get events -n <namespace-name>
```