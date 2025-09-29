# Infrastructure Plan: Kubernetes on AWS with Rancher

## Overview
Deploy a complete Kubernetes infrastructure on AWS with Rancher management, Traefik ingress, and automated deployments via GitHub Actions. Traffic will flow from `dev.emelz.org` through Route53 → EC2 instance → Nginx → Traefik → Kubernetes services.

## Phase 1: AWS Infrastructure Setup

### 1.1 Terraform AWS Configuration
- Configure Terraform to use `emelz-org-admin` profile
- Define AWS provider for `us-west-2` region (account: 057581197427)
- Set up remote state backend (S3 + DynamoDB for locking)

### 1.2 Network Infrastructure
- Create VPC with public/private subnets
- Configure Internet Gateway
- Set up security groups:
  - SSH access (port 22)
  - HTTP/HTTPS (ports 80, 443)
  - Kubernetes API (port 6443)
  - Rancher UI (port 443)
  - Tailscale (UDP port 41641)

### 1.3 EC2 Instance
- Launch EC2 instance (recommended: t3.large or larger for Rancher)
- Ubuntu 22.04 LTS AMI
- Attach elastic IP for stable external address
- Configure instance profile with necessary IAM roles
- Install base dependencies: Docker, kubectl, helm

## Phase 2: Rancher Installation

### 2.1 K3s Installation (Lightweight Kubernetes)
- Use Terraform provisioner or cloud-init to install K3s
- K3s comes with Traefik by default (will configure later)
- Verify cluster is operational

### 2.2 Rancher Deployment
- Install Rancher via Helm chart on K3s cluster
- Configure Rancher with Let's Encrypt certificates
- Set up admin user and access
- Alternative: Use Terraform Rancher2 provider for automation

### 2.3 Rancher Configuration
- Import/register the K3s cluster into Rancher
- Configure project namespaces
- Set up RBAC policies

## Phase 3: Tailscale Setup

### 3.1 Tailscale Installation
- Install Tailscale on EC2 instance
- Authenticate with Tailscale network
- Enable subnet routing if needed
- Document Tailscale IP for private access

### 3.2 Security Configuration
- Configure security groups to allow Tailscale traffic
- Set up MagicDNS for easy access to instance
- Consider Tailscale ACLs for access control

## Phase 4: Nginx Reverse Proxy

### 4.1 Nginx Installation & Configuration
- Install Nginx on EC2 instance (outside Kubernetes)
- Configure as reverse proxy to Traefik ingress controller
- Set up SSL/TLS termination with Let's Encrypt (certbot)
- Configure upstream to Traefik (typically localhost:80/443 or K3s service IP)

### 4.2 Nginx Routing Rules
- Route traffic for `dev.emelz.org` to Traefik
- Configure health checks
- Set up logging and monitoring
- Handle WebSocket connections if needed

## Phase 5: Traefik Ingress Configuration

### 5.1 Traefik Setup
- Configure Traefik ingress controller (comes with K3s)
- Set up IngressRoute CRDs for routing
- Configure middleware (headers, auth, rate limiting)
- Enable Traefik dashboard (secured)

### 5.2 Ingress Rules
- Create IngressRoute for demo application
- Configure host-based routing for `dev.emelz.org`
- Set up TLS certificates (Let's Encrypt via cert-manager or Traefik's built-in ACME)
- Configure path-based routing if needed

## Phase 6: Route53 DNS Configuration

### 6.1 Domain Setup
- Verify `emelz.org` domain is in Route53
- Create A record for `dev.emelz.org` pointing to EC2 elastic IP
- Set appropriate TTL (300 seconds for testing, higher for production)
- Consider health checks for automatic failover

### 6.2 DNS Validation
- Test DNS resolution from multiple locations
- Verify propagation
- Set up DNS monitoring

## Phase 7: Demo Application Deployment

### 7.1 Application Setup
- Create simple demo application (e.g., nginx, hello-world, or custom app)
- Build Docker image and push to container registry (ECR or Docker Hub)
- Create Kubernetes manifests:
  - Deployment
  - Service (ClusterIP)
  - IngressRoute (Traefik)

### 7.2 Manual Deployment Test
- Deploy application via kubectl
- Verify pods are running
- Test service connectivity within cluster
- Verify Traefik ingress routing

## Phase 8: GitHub Actions CI/CD

### 8.1 GitHub Repository Setup
- Create demo application repository
- Set up GitHub secrets:
  - AWS credentials (or OIDC)
  - Kubeconfig or service account token
  - Container registry credentials

### 8.2 GitHub Actions Workflow
- Build Docker image on push to main branch
- Tag and push image to registry
- Update Kubernetes deployment with new image
- Use kubectl or Helm for deployment
- Add deployment notifications (Slack, email, etc.)

### 8.3 GitOps (Optional Enhancement)
- Consider ArgoCD or FluxCD for GitOps workflow
- Automated sync from Git repository to cluster
- Declarative infrastructure management

## Phase 9: End-to-End Integration Testing

### 9.1 Traffic Flow Validation
- Test complete path: Browser → Route53 → EC2 → Nginx → Traefik → Pod
- Verify SSL/TLS certificates at each layer
- Test with curl and browser
- Validate response headers and content

### 9.2 Monitoring & Observability
- Set up CloudWatch for EC2 metrics
- Configure Nginx access/error logs
- Enable Traefik metrics and dashboard
- Set up Kubernetes monitoring (Prometheus + Grafana optional)

### 9.3 Demo Scenarios
- HTTP request to `https://dev.emelz.org`
- Path-based routing tests
- WebSocket connection test (if applicable)
- Load testing (optional)
- Failure scenario testing (pod restart, node issues)

## Phase 10: Documentation & Cleanup

### 10.1 Documentation
- Document all credentials and access methods
- Create runbook for common operations
- Update CLAUDE.md with deployment procedures
- Document troubleshooting steps

### 10.2 Cost Optimization
- Review AWS resource costs
- Set up billing alerts
- Consider spot instances for non-production
- Implement auto-scaling policies

### 10.3 Security Hardening
- Review security group rules (principle of least privilege)
- Enable AWS CloudTrail logging
- Configure automatic security updates
- Set up secrets management (AWS Secrets Manager or Vault)
- Regular security scanning of container images

## Success Criteria

1. ✅ Terraform deploys complete infrastructure with single `terraform apply`
2. ✅ Browser can access `https://dev.emelz.org` with valid SSL certificate
3. ✅ Traffic successfully routes through all layers (Route53 → Nginx → Traefik → Pod)
4. ✅ GitHub Actions automatically deploys application updates
5. ✅ Rancher UI accessible for cluster management
6. ✅ Tailscale provides secure private access to instance
7. ✅ Complete demo workflow documented and repeatable

## Technology Stack Summary

- **Infrastructure**: AWS (EC2, VPC, Route53, IAM)
- **IaC**: Terraform
- **Kubernetes**: K3s (lightweight Kubernetes)
- **Cluster Management**: Rancher
- **Ingress Controller**: Traefik
- **Reverse Proxy**: Nginx
- **VPN**: Tailscale
- **CI/CD**: GitHub Actions
- **Certificates**: Let's Encrypt (via cert-manager or ACME)
- **Container Registry**: AWS ECR or Docker Hub

## Next Steps

1. Start with Phase 1: Set up Terraform and AWS infrastructure
2. Test each phase independently before moving to the next
3. Maintain infrastructure as code in this repository
4. Iterate and refine based on testing and requirements