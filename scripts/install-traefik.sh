#!/bin/bash
set -e

echo "=== Installing Traefik Ingress Controller ==="

# Install Traefik CRDs
echo "Installing Traefik CRDs..."
sudo k3s kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
sudo k3s kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml

# Deploy Traefik
echo "Deploying Traefik..."
cat <<EOF | sudo k3s kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: traefik
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik
  namespace: traefik
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  namespace: traefik
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik
      containers:
      - name: traefik
        image: traefik:v2.10
        args:
        - --entrypoints.web.address=:80
        - --providers.kubernetesingress
        - --providers.kubernetescrd
        - --api.insecure=true
        - --log.level=INFO
        ports:
        - name: web
          containerPort: 80
        - name: dashboard
          containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: traefik
spec:
  type: NodePort
  ports:
  - name: web
    port: 80
    targetPort: 80
    nodePort: 30080
  - name: dashboard
    port: 8080
    targetPort: 8080
  selector:
    app: traefik
EOF

# Fix RBAC permissions
echo "Configuring RBAC..."
cat <<EOF | sudo k3s kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-ingress-controller
subjects:
- kind: ServiceAccount
  name: traefik
  namespace: traefik
EOF

# Wait for Traefik to be ready
echo "Waiting for Traefik to be ready..."
sudo k3s kubectl -n traefik rollout status deployment/traefik --timeout=120s

echo "✓ Traefik installed successfully"
sudo k3s kubectl -n traefik get pods

echo "=== Traefik installation complete ==="