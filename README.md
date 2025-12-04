# MCK-infra

Infrastructure as Code for AWS using Terraform modules.

## Overview

This repository contains Terraform modules for deploying production-ready AWS infrastructure:

- **VPC Module** (`modules/vpc`) - VPC with public/private subnets, NAT Gateway, Internet Gateway
- **EKS Module** (`modules/eks`) - Amazon EKS cluster with managed node groups and OIDC
- **KMS Module** (coming soon) - KMS keys for encryption at rest

## Project Structure

```
MCK-infra/
├── main.tf              # Root module - calls VPC and EKS modules
├── README.md            # This file
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md    # VPC module documentation
│   └── eks/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md    # EKS module documentation
```

## Quick Start

```bash
# Clone the repository
git clone <repo-url>
cd MCK-infra

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name mck-dev-eks

# Verify cluster
kubectl get nodes
```

## Using the Modules

### 1. VPC Module

Create a VPC with public and private subnets:

```hcl
module "vpc" {
  source = "./modules/vpc"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = true
  enable_security_group = false

  tags = {
    Environment = "production"
  }
}
```

**See [`modules/vpc/README.md`](modules/vpc/README.md) for detailed documentation.**

### 2. EKS Module

Create an EKS cluster using VPC outputs:

```hcl
module "eks" {
  source = "./modules/eks"

  region          = "us-east-1"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"

  # Use VPC module outputs
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # API access
  enable_public_access  = true
  enable_private_access = true

  # Node group
  node_group_min_size       = 2
  node_group_desired_size   = 2
  node_group_max_size       = 4
  node_group_instance_types = ["t3.medium"]

  tags = {
    Environment = "production"
  }
}
```

**See [`modules/eks/README.md`](modules/eks/README.md) for detailed documentation.**

### 3. Complete Example

Here's how to use both modules together:

```hcl
# Provider configuration
provider "aws" {
  region = "us-east-1"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  name       = "prod-vpc"
  cidr_block = "10.0.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = true
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  region          = "us-east-1"
  cluster_name    = "prod-eks"
  cluster_version = "1.29"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  node_group_min_size     = 2
  node_group_desired_size = 3
  node_group_max_size     = 5
}

# Outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
```

## Module Outputs

### VPC Module Outputs

Access VPC module outputs using:

```hcl
module.vpc.vpc_id
module.vpc.public_subnet_ids
module.vpc.private_subnet_ids
module.vpc.nat_gateway_id
```

### EKS Module Outputs

Access EKS module outputs using:

```hcl
module.eks.cluster_name
module.eks.cluster_endpoint
module.eks.cluster_ca_certificate
module.eks.cluster_oidc_issuer
```

## Configuration

The root `main.tf` file contains hardcoded values for testing. To customize:

1. Edit `main.tf` directly, OR
2. Convert hardcoded values to variables

### Key Configuration Options

| Setting | Location | Default | Description |
|---------|----------|---------|-------------|
| Region | `main.tf` | `us-east-1` | AWS region |
| VPC CIDR | `main.tf` | `10.0.0.0/16` | VPC CIDR block |
| EKS Version | `main.tf` | `1.29` | Kubernetes version |
| Node Type | `main.tf` | `t3.medium` | EC2 instance type |
| Node Count | `main.tf` | 2-4 | Min/Max nodes |

## KMS Encryption (Optional)

The EKS module supports optional KMS encryption for secrets at rest. Pass a KMS key ARN from a separate KMS module:

```hcl
module "eks" {
  source = "./modules/eks"
  
  # ... other config ...
  
  # Pass KMS key from KMS module
  kms_key_arn = module.kms.eks_kms_key_arn
}
```

**Note**: KMS module will be added in the future.

## Security Features

### VPC Module Security

- ✅ Built-in validations (no SSH/RDP from 0.0.0.0/0)
- ✅ Restricted egress by default (HTTPS, HTTP, DNS only)
- ✅ Customizable security group rules

### EKS Module Security

- ✅ API access can be restricted to VPC CIDR
- ✅ Private endpoint support
- ✅ OIDC provider for IRSA
- ✅ Security group validations
- ✅ Optional KMS encryption support

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                 VPC (10.0.0.0/16)                   │
├──────────────────────┬──────────────────────────────┤
│   Public Subnets     │      Private Subnets         │
│   - 10.0.0.0/24      │      - 10.0.10.0/24          │
│   - 10.0.1.0/24      │      - 10.0.11.0/24          │
│                      │                              │
│   [Internet Gateway] │      [NAT Gateway]           │
│                      │                              │
│                      │   ┌────────────────────┐     │
│                      │   │  EKS Control Plane │     │
│                      │   └────────────────────┘     │
│                      │                              │
│                      │   ┌────────────────────┐     │
│                      │   │  EKS Worker Nodes  │     │
│                      │   │  (Managed Node Grp)│     │
│                      │   └────────────────────┘     │
└──────────────────────┴──────────────────────────────┘
```

## Cost Estimate (us-east-1)

| Resource | Configuration | Monthly Cost (approx) |
|----------|--------------|----------------------|
| VPC | Standard | Free |
| NAT Gateway | 1 instance | ~$32 |
| EKS Control Plane | 1 cluster | $73 |
| EC2 (t3.medium) | 2 nodes | ~$60 |
| EBS Volumes | 40GB (2x20GB) | ~$4 |
| **Total** | | **~$169/month** |

*Costs exclude data transfer and may vary by region*

## Post-Deployment

### Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name mck-dev-eks
```

### Verify Cluster

```bash
# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Check EBS CSI driver
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

### Deploy Sample Application

```bash
# Create a deployment
kubectl create deployment nginx --image=nginx

# Expose it
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Get the LoadBalancer URL
kubectl get svc nginx
```

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Note: This will delete:
# - EKS cluster and node groups
# - NAT Gateway
# - VPC and all networking resources
```

## Module Documentation

- **VPC Module**: See [`modules/vpc/README.md`](modules/vpc/README.md)
- **EKS Module**: See [`modules/eks/README.md`](modules/eks/README.md)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | ~> 5.0 |

## Support

For issues or questions about specific modules, refer to their respective README files.
