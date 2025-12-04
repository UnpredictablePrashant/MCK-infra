# EKS Module

Terraform module for deploying Amazon EKS cluster with managed node groups, OIDC provider, and security best practices.

## Features

- ✅ EKS Control Plane with configurable Kubernetes version
- ✅ Managed Node Groups with auto-scaling
- ✅ OIDC Provider for IRSA (IAM Roles for Service Accounts)
- ✅ EBS CSI Driver with IRSA configuration
- ✅ VPC CNI addon
- ✅ Configurable security groups
- ✅ Public and private API endpoint access
- ✅ Optional KMS encryption support

## Usage

### Basic Configuration

```hcl
module "eks" {
  source = "./modules/eks"

  region          = "us-east-1"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"

  # Network configuration (from VPC module)
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
    Environment = "dev"
  }
}
```

### With Custom Security Group

```hcl
module "eks" {
  source = "./modules/eks"

  region          = "us-east-1"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Custom security group
  create_cluster_security_group = true
  
  cluster_security_group_ingress_rules = [
    {
      description = "API access from VPC"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]

  allow_all_cluster_egress = false
}
```

### With KMS Encryption

KMS key should be created in a separate KMS module and passed as a variable:

```hcl
module "eks" {
  source = "./modules/eks"

  region          = "us-east-1"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Pass KMS key ARN from KMS module
  kms_key_arn = module.kms.eks_kms_key_arn

  node_group_min_size     = 2
  node_group_desired_size = 2
  node_group_max_size     = 4
}
```

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `cluster_name` | string | Name of the EKS cluster |
| `vpc_id` | string | VPC ID where EKS will run |
| `private_subnet_ids` | list(string) | Private subnet IDs for EKS |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `region` | string | - | AWS region |
| `cluster_version` | string | `"1.29"` | Kubernetes version |
| `kms_key_arn` | string | `""` | Optional KMS key ARN for encryption |
| `enable_public_access` | bool | `true` | Enable public API access |
| `enable_private_access` | bool | `true` | Enable private API access |
| `cluster_endpoint_public_access_cidrs` | list(string) | `["0.0.0.0/0"]` | CIDRs for public API access |

### Security Group Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `create_cluster_security_group` | bool | `true` | Create security group |
| `cluster_security_group_id` | string | `""` | Existing SG ID (if not creating) |
| `cluster_security_group_ingress_rules` | list(object) | `[]` | Ingress rules |
| `cluster_security_group_additional_rules` | list(object) | `[]` | Additional rules with SG support |
| `allow_all_cluster_egress` | bool | `false` | Allow all egress |

### Node Group Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `node_group_min_size` | number | `2` | Minimum nodes |
| `node_group_desired_size` | number | `3` | Desired nodes |
| `node_group_max_size` | number | `6` | Maximum nodes |
| `node_group_instance_types` | list(string) | `["t3.medium"]` | Instance types |
| `node_group_capacity_type` | string | `"ON_DEMAND"` | ON_DEMAND or SPOT |
| `node_group_disk_size` | number | `20` | Disk size in GiB |
| `node_group_labels` | map(string) | `{}` | Kubernetes labels |
| `node_group_tags` | map(string) | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_arn` | EKS cluster ARN |
| `cluster_endpoint` | EKS API endpoint |
| `cluster_ca_certificate` | Cluster CA certificate (base64) |
| `cluster_security_group_id` | Security group ID |
| `cluster_oidc_issuer` | OIDC issuer URL for IRSA |
| `node_group_name` | Node group name |
| `node_group_iam_role_arn` | Node group IAM role ARN |

## Security Features

### Security Group Rules

The module implements security best practices:

- API access restricted to specific CIDRs (not 0.0.0.0/0 by default)
- Support for self-referencing rules (node ↔ control plane)
- Controlled egress (HTTPS only by default)
- Validation to prevent SSH/RDP from 0.0.0.0/0

### IAM Roles

The module creates:
- **Cluster Role**: For EKS control plane
- **Node Group Role**: For worker nodes
- **EBS CSI Role**: For EBS volume provisioning (IRSA)

### OIDC Provider

OIDC provider is automatically created for IRSA, allowing Kubernetes service accounts to assume IAM roles securely.

## KMS Encryption

The module accepts an optional `kms_key_arn` variable for encrypting Kubernetes secrets at rest. The KMS key should be created in a separate KMS module.

**Note**: 
- KMS encryption cannot be disabled after cluster creation
- KMS key must be in the same region as the cluster
- KMS key policy must allow EKS service to use it

## Examples

### Production Cluster

```hcl
module "eks" {
  source = "./modules/eks"

  region          = "us-east-1"
  cluster_name    = "prod-eks"
  cluster_version = "1.29"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Restrict API access
  enable_public_access                 = false
  enable_private_access                = true
  cluster_endpoint_public_access_cidrs = []

  # Secure security group
  cluster_security_group_ingress_rules = [
    {
      description = "API from VPC only"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]

  # KMS encryption (from KMS module)
  kms_key_arn = module.kms.eks_kms_key_arn

  # Production node group
  node_group_min_size       = 3
  node_group_desired_size   = 5
  node_group_max_size       = 10
  node_group_instance_types = ["t3.large"]
  node_group_capacity_type  = "ON_DEMAND"

  tags = {
    Environment = "production"
    Critical    = "true"
  }
}
```

### Dev Cluster (Cost-Optimized)

```hcl
module "eks" {
  source = "./modules/eks"

  region          = "us-east-1"
  cluster_name    = "dev-eks"
  cluster_version = "1.29"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Public access for dev
  enable_public_access  = true
  enable_private_access = true

  # No KMS encryption for cost savings
  # kms_key_arn = ""

  # SPOT instances
  node_group_min_size       = 2
  node_group_desired_size   = 2
  node_group_max_size       = 3
  node_group_instance_types = ["t3.medium"]
  node_group_capacity_type  = "SPOT"

  tags = {
    Environment = "development"
  }
}
```

## EKS Addons

The module automatically installs:
- **vpc-cni**: For pod networking
- **aws-ebs-csi-driver**: For EBS volume provisioning

## Cost Estimate (us-east-1)

| Resource | Configuration | Monthly Cost |
|----------|--------------|--------------|
| EKS Control Plane | 1 cluster | $73 |
| EC2 t3.medium | 2 nodes (ON_DEMAND) | ~$60 |
| EBS Volumes | 40GB (2x20GB) | ~$4 |
| KMS (optional) | If used | ~$1 |
| **Total** | | **~$137-138** |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | ~> 5.0 |

