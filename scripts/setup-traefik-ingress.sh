#!/bin/bash
set -e

echo "=== Setting up Traefik Ingress Controller ==="

# Set kubeconfig
export KUBECONFIG=/Users/ericmelz/.kube/k3s-tailscale.yaml

echo "1. Adding Traefik Helm repository..."
helm repo add traefik https://traefik.github.io/charts
helm repo update

echo "2. Installing Traefik..."
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set ports.web.port=80 \
  --set ports.websecure.port=443 \
  --set ports.websecure.tls.enabled=true \
  --set ingressClass.enabled=true \
  --set ingressClass.isDefaultClass=true

echo "3. Waiting for Traefik to be ready..."
kubectl wait --namespace traefik \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=traefik \
  --timeout=120s

echo "4. Applying Traefik IngressRoute resources for hosty..."
kubectl apply -f apps/hosty/k8s/ingress/traefik-ingressroute-dev.yaml
kubectl apply -f apps/hosty/k8s/ingress/traefik-ingressroute-prod.yaml

echo ""
echo "=== Traefik Ingress Setup Complete ==="
echo ""
echo "IngressRoute resources created:"
kubectl get ingressroute -n dev-weighter-net
kubectl get ingressroute -n weighter-org
echo ""
echo "To get the Traefik external IP:"
echo "  kubectl get svc -n traefik traefik"
echo ""
echo "Configure your DNS to point to this IP:"
echo "  dev.weighter.net -> <EXTERNAL_IP>"
echo "  weighter.org -> <EXTERNAL_IP>"
echo "  www.weighter.org -> <EXTERNAL_IP>"