#!/bin/bash
set -e

echo "=== Setting up nginx Ingress Controller ==="

# Set kubeconfig
export KUBECONFIG=/Users/ericmelz/.kube/k3s-tailscale.yaml

echo "1. Installing nginx Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/cloud/deploy.yaml

echo "2. Waiting for nginx ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "3. Applying ingress resources for hosty..."
kubectl apply -f apps/hosty/k8s/ingress/nginx-ingress-dev.yaml
kubectl apply -f apps/hosty/k8s/ingress/nginx-ingress-prod.yaml

echo ""
echo "=== nginx Ingress Setup Complete ==="
echo ""
echo "Ingress resources created:"
kubectl get ingress -n dev-weighter-net
kubectl get ingress -n weighter-org
echo ""
echo "To get the ingress controller external IP:"
echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller"
echo ""
echo "Configure your DNS to point to this IP:"
echo "  dev.weighter.net -> <EXTERNAL_IP>"
echo "  weighter.org -> <EXTERNAL_IP>"
echo "  www.weighter.org -> <EXTERNAL_IP>"