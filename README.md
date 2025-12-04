# MCK-infra

Infrastructure as Code for AWS using Terraform modules.

## Overview

This repository contains Terraform modules for deploying production-ready AWS infrastructure:

- **VPC Module** (`modules/vpc`) - VPC with public/private subnets, NAT Gateway, Internet Gateway
- **IAM Module** (`modules/iam`) - IAM roles and policies for EKS cluster and nodes with KMS permissions
- **KMS Module** (`modules/kms`) - KMS keys for encryption at rest with comprehensive service policies
- **EKS Module** (`modules/eks`) - Amazon EKS cluster with Auto Mode support, managed node groups, OIDC, and optional external IAM roles

## Project Structure

```
MCK-infra/
├── main.tf              # Module orchestration (locals + module calls)
├── provider.tf          # AWS provider configuration
├── versions.tf          # Terraform and provider version requirements
├── outputs.tf           # All infrastructure outputs
├── README.md            # This file
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md    # VPC module documentation
│   ├── iam/
│   │   ├── iam.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md    # IAM module documentation
│   ├── kms/
│   │   ├── kms.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md    # KMS module documentation
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

### 3. IAM Module

Create IAM roles with enhanced permissions for EKS:

```hcl
module "iam" {
  source = "./modules/iam"

  project_name               = "my-project"
  environment                = "production"
  cluster_name               = "my-eks-cluster"
  cluster_role_name          = "my-eks-cluster-role"
  node_role_name             = "my-eks-node-role"
  node_instance_profile_name = "my-eks-node-profile"

  tags = {
    Environment = "production"
  }
}
```

**See [`modules/iam/README.md`](modules/iam/README.md) for detailed documentation.**

### 4. KMS Module

Create KMS key for encryption at rest:

```hcl
module "kms" {
  source = "./modules/kms"

  project_name             = "my-project"
  environment              = "production"
  kms_alias_name           = "my-eks-encryption"
  kms_deletion_window_days = 30
  kms_enable_key_rotation  = true

  tags = {
    Environment = "production"
  }
}
```

**See [`modules/kms/README.md`](modules/kms/README.md) for detailed documentation.**

### 5. Complete Example (All Modules)

Here's how to use all modules together with best practices:

```hcl
# Provider configuration
provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "MyProject"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}

# Local values
locals {
  cluster_name = "prod-eks"
  common_tags = {
    Project     = "MyProject"
    Environment = "production"
  }
}

# 1. VPC Module
module "vpc" {
  source = "./modules/vpc"

  name       = "prod-vpc"
  cidr_block = "10.0.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = true
  tags               = local.common_tags
}

# 2. KMS Module (for encryption)
module "kms" {
  source = "./modules/kms"

  project_name             = "myproject"
  environment              = "production"
  kms_alias_name           = "prod-eks-encryption"
  kms_deletion_window_days = 30
  kms_enable_key_rotation  = true

  tags = local.common_tags
}

# 3. IAM Module (roles for EKS)
module "iam" {
  source = "./modules/iam"

  depends_on = [module.kms]

  project_name      = "myproject"
  environment       = "production"
  cluster_name      = local.cluster_name
  cluster_role_name = "${local.cluster_name}-cluster-role"
  node_role_name    = "${local.cluster_name}-node-role"

  tags = local.common_tags
}

# 4. EKS Module (using all above modules)
module "eks" {
  source = "./modules/eks"

  depends_on = [module.vpc, module.iam, module.kms]

  region          = "us-east-1"
  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  # Network from VPC module
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # IAM from IAM module
  create_iam_roles = false
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn

  # Encryption from KMS module
  kms_key_arn = module.kms.kms_key_arn

  # Node configuration
  node_group_min_size       = 2
  node_group_desired_size   = 3
  node_group_max_size       = 5
  node_group_instance_types = ["t3.medium"]

  tags = local.common_tags
}

# Outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kms_key_arn" {
  value = module.kms.kms_key_arn
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name}"
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
module.eks.cluster_iam_role_arn
module.eks.node_group_iam_role_arn
```

### IAM Module Outputs

Access IAM module outputs using:

```hcl
module.iam.eks_cluster_role_arn
module.iam.eks_cluster_role_name
module.iam.eks_node_role_arn
module.iam.eks_node_role_name
module.iam.eks_node_instance_profile
```

### KMS Module Outputs

Access KMS module outputs using:

```hcl
module.kms.kms_key_id
module.kms.kms_key_arn
module.kms.kms_alias
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

## KMS Encryption

The infrastructure now includes a dedicated KMS module for encryption at rest:

```hcl
module "kms" {
  source = "./modules/kms"
  
  kms_alias_name           = "prod-eks-encryption"
  kms_enable_key_rotation  = true
  kms_deletion_window_days = 30
  
  tags = local.common_tags
}

module "eks" {
  source = "./modules/eks"
  
  # ... other config ...
  
  # Use KMS key from KMS module
  kms_key_arn = module.kms.kms_key_arn
}
```

**Benefits**:
- Automatic key rotation
- Encryption of Kubernetes secrets in etcd
- Encryption of EBS volumes
- Compliance with security standards (HIPAA, PCI DSS, SOC 2)

## Security Features

### VPC Module Security

- ✅ Built-in validations (no SSH/RDP from 0.0.0.0/0)
- ✅ Restricted egress by default (HTTPS, HTTP, DNS only)
- ✅ Customizable security group rules

### IAM Module Security

- ✅ Least privilege IAM policies
- ✅ KMS encryption permissions
- ✅ Service-specific assume role policies
- ✅ Auto-scaling permissions for cluster autoscaler
- ✅ VPC networking permissions

### KMS Module Security

- ✅ Automatic key rotation enabled
- ✅ Service-specific key policies (EKS, EC2)
- ✅ Configurable deletion window
- ✅ CloudTrail integration for audit logs
- ✅ FIPS 140-2 Level 2 compliance

### EKS Module Security

- ✅ **EKS Auto Mode** for automated node management
- ✅ API access can be restricted to VPC CIDR
- ✅ Private endpoint support
- ✅ OIDC provider for IRSA
- ✅ Security group validations
- ✅ KMS encryption for secrets at rest
- ✅ Support for external IAM roles

## Architecture

```
                    ┌──────────────────┐
                    │   KMS Module     │
                    │  (Encryption)    │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │   IAM Module     │
                    │  (Roles/Policies)│
                    └────────┬─────────┘
                             │
┌────────────────────────────▼─────────────────────────┐
│                 VPC (10.0.0.0/16)                    │
├──────────────────────┬───────────────────────────────┤
│   Public Subnets     │      Private Subnets          │
│   - 10.0.0.0/24      │      - 10.0.10.0/24           │
│   - 10.0.1.0/24      │      - 10.0.11.0/24           │
│                      │                               │
│   [Internet Gateway] │      [NAT Gateway]            │
│                      │                               │
│                      │   ┌─────────────────────┐     │
│                      │   │  EKS Control Plane  │     │
│                      │   │  (with IAM + KMS)   │     │
│                      │   └─────────────────────┘     │
│                      │                               │
│                      │   ┌─────────────────────┐     │
│                      │   │  EKS Worker Nodes   │     │
│                      │   │  (Managed Node Grp) │     │
│                      │   │  (with IAM + KMS)   │     │
│                      │   └─────────────────────┘     │
└──────────────────────┴───────────────────────────────┘
```

## Cost Estimate (us-east-1)

| Resource | Configuration | Monthly Cost (approx) |
|----------|--------------|----------------------|
| VPC | Standard | Free |
| NAT Gateway | 1 instance | ~$32 |
| KMS Key | 1 key | ~$1 |
| IAM Roles | All roles | Free |
| EKS Control Plane | 1 cluster | $73 |
| EC2 (t3.medium) | 2 nodes | ~$60 |
| EBS Volumes | 40GB (2x20GB) | ~$4 |
| **Total** | | **~$170/month** |

*Costs exclude data transfer, KMS API requests, and may vary by region*

### Cost Optimization Tips

- **Development**: Use SPOT instances, disable KMS rotation
- **Production**: Use ON_DEMAND, enable KMS rotation
- **Multi-AZ**: Cost scales with number of NAT Gateways

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
- **IAM Module**: See [`modules/iam/README.md`](modules/iam/README.md)
- **KMS Module**: See [`modules/kms/README.md`](modules/kms/README.md)
- **EKS Module**: See [`modules/eks/README.md`](modules/eks/README.md)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | ~> 5.0 |

## Support

For issues or questions about specific modules, refer to their respective README files.
