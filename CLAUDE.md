# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform project for provisioning Kubernetes infrastructure on AWS or on-premises environments. The infrastructure includes additional configuration for services like nginx for reverse-proxying.

## Development Commands

### Terraform Workflow
```bash
# Initialize Terraform (run after cloning or adding new providers)
terraform init

# Validate configuration
terraform validate

# Plan infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply

# Destroy infrastructure
terraform destroy

# Format Terraform files
terraform fmt -recursive

# Show current state
terraform show
```

### Working with Specific Environments
```bash
# Use workspaces for different environments
terraform workspace list
terraform workspace select <environment>
terraform workspace new <environment>

# Or use variable files
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

## Architecture Notes

This repository is intended to provision:
- Kubernetes clusters (AWS EKS or on-premises)
- Networking and security group configuration
- Nginx ingress controller or reverse proxy setup
- Supporting infrastructure components

When adding new Terraform resources:
- Organize by logical components (e.g., `modules/k8s/`, `modules/networking/`)
- Use modules for reusable infrastructure patterns
- Separate provider configurations for AWS vs on-premises deployments
- Keep environment-specific variables in separate tfvars files
- Use remote state backend for team collaboration