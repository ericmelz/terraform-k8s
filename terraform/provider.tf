terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "emelz-org-admin"

  default_tags {
    tags = {
      Project     = "terraform-k8s"
      ManagedBy   = "Terraform"
      Environment = "dev"
    }
  }
}