# Terraform Modules Documentation

## 🎯 Overview

This directory contains shared Terraform modules used by both EKS-Infra-1 and EKS-Infra-2. All modules are designed to be reusable and production-ready.

---

## 📦 Available Modules

### 1. VPC Module (`vpc/`)
Creates a complete VPC infrastructure with public and private subnets.

**Features**:
- Multi-AZ deployment
- Public and private subnets
- Internet Gateway
- NAT Gateway
- Route tables
- Security groups (optional)

**Usage**:
```hcl
module "vpc" {
  source = "../modules/vpc"
  
  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]
  
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
  
  enable_vpc              = true
  enable_internet_gateway = true
  enable_nat_gateway      = true
  enable_route_tables     = true
  
  tags = { Environment = "dev" }
}
```

**Outputs**:
- `vpc_id` - VPC ID
- `vpc_cidr` - VPC CIDR block
- `public_subnet_ids` - List of public subnet IDs
- `private_subnet_ids` - List of private subnet IDs
- `nat_gateway_ids` - NAT Gateway IDs

---

### 2. KMS Module (`kms/`)
Creates KMS keys for encryption with automatic rotation.

**Features**:
- Customer-managed KMS keys
- Automatic key rotation
- Key aliases
- Configurable deletion window

**Usage**:
```hcl
module "kms" {
  source = "../modules/kms"
  
  project_name             = "my-project"
  environment              = "dev"
  kms_key_description      = "KMS key for EKS encryption"
  kms_alias_name           = "my-eks-encryption"
  kms_deletion_window_days = 10
  kms_enable_key_rotation  = true
  
  tags = { Environment = "dev" }
}
```

**Outputs**:
- `kms_key_id` - KMS key ID
- `kms_key_arn` - KMS key ARN
- `kms_key_alias` - KMS key alias

---

### 3. IAM Module (`iam/`)
Creates IAM roles for EKS cluster and worker nodes.

**Features**:
- EKS cluster role
- EKS node role
- EC2 instance profile
- Managed policy attachments
- KMS permissions

**Usage**:
```hcl
module "iam" {
  source = "../modules/iam"
  
  project_name               = "my-project"
  environment                = "dev"
  region                     = "us-east-1"
  cluster_name               = "my-eks"
  cluster_version            = "1.34"
  cluster_role_name          = "my-eks-cluster-role"
  node_role_name             = "my-eks-node-role"
  node_instance_profile_name = "my-eks-node-profile"
  
  tags = { Environment = "dev" }
}
```

**Outputs**:
- `eks_cluster_role_arn` - EKS cluster role ARN
- `eks_node_role_arn` - EKS node role ARN
- `eks_node_instance_profile_name` - Instance profile name

---

### 4. EKS Module (`eks/`)
Creates a complete EKS cluster with managed node groups and IAM Access Entries.

**Features**:
- EKS cluster with configurable version
- Managed node groups
- IAM Access Entries support
- API_AND_CONFIG_MAP authentication mode
- KMS encryption
- Security groups
- OIDC provider for IRSA
- EKS addons (VPC CNI, EBS CSI)

**Usage**:
```hcl
module "eks" {
  source = "../modules/eks"
  
  region          = "us-east-1"
  cluster_name    = "my-eks"
  cluster_version = "1.34"
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  create_iam_roles = false
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn
  
  kms_key_arn = module.kms.kms_key_arn
  
  authentication_mode        = "API_AND_CONFIG_MAP"
  enable_iam_access_entries  = true
  
  access_entries = {
    "arn:aws:iam::ACCOUNT:role/admin" = {
      kubernetes_groups = []
      type              = "STANDARD"
    }
  }
  
  access_entry_policy_associations = {
    "admin-cluster-admin" = {
      principal_arn = "arn:aws:iam::ACCOUNT:role/admin"
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope  = { type = "cluster" }
    }
  }
  
  node_group_min_size       = 2
  node_group_desired_size   = 2
  node_group_max_size       = 4
  node_group_instance_types = ["t3.medium"]
  
  tags = { Environment = "dev" }
}
```

**Outputs**:
- `cluster_name` - EKS cluster name
- `cluster_arn` - EKS cluster ARN
- `cluster_endpoint` - EKS API endpoint
- `cluster_ca_certificate` - CA certificate
- `cluster_security_group_id` - Security group ID
- `cluster_oidc_issuer` - OIDC issuer URL
- `authentication_mode` - Authentication mode
- `access_entries` - IAM access entries
- `access_entry_policy_associations` - Policy associations

---

### 5. ECR Module (`ecr/`)
Creates ECR repositories for container images.

**Features**:
- Multiple repositories
- Image scanning on push
- KMS encryption
- Lifecycle policies
- Configurable image retention

**Usage**:
```hcl
module "ecr" {
  source = "../modules/ecr"
  
  project_name            = "my-project"
  environment             = "dev"
  repository_names        = ["app", "api", "worker"]
  image_tag_mutability    = "MUTABLE"
  scan_on_push            = true
  enable_encryption       = true
  kms_key_id              = module.kms.kms_key_id
  enable_lifecycle_policy = true
  image_expiration_days   = 7
  max_image_count         = 10
  
  tags = { Environment = "dev" }
}
```

**Outputs**:
- `repository_urls` - Map of repository URLs
- `repository_arns` - Map of repository ARNs

---

## 🔧 Module Structure

Each module follows this structure:

```
module-name/
├── main.tf       # Main resource definitions
├── variables.tf  # Input variables
├── outputs.tf    # Output values
├── data.tf       # Data sources (if needed)
├── locals.tf     # Local values (if needed)
├── versions.tf   # Provider version requirements
└── README.md     # Module-specific documentation
```

---

## 🎯 Best Practices

### 1. Version Pinning
Always pin module versions in production:
```hcl
module "vpc" {
  source = "../modules/vpc"
  # version = "1.0.0"  # Uncomment when using versioned modules
}
```

### 2. Variable Validation
Modules include input validation:
```hcl
variable "cluster_version" {
  type    = string
  default = "1.29"
  
  validation {
    condition     = can(regex("^1\\.(2[89]|3[0-9])$", var.cluster_version))
    error_message = "Cluster version must be 1.28 or higher"
  }
}
```

### 3. Tagging
Always pass consistent tags:
```hcl
locals {
  common_tags = {
    Project     = "my-project"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source = "../modules/vpc"
  # ... other config ...
  tags = local.common_tags
}
```

### 4. Dependencies
Use `depends_on` when needed:
```hcl
module "eks" {
  source = "../modules/eks"
  
  depends_on = [module.vpc, module.iam, module.kms]
  # ... config ...
}
```

---

## 🔐 Security Considerations

### KMS Encryption
- All modules support KMS encryption where applicable
- Use customer-managed keys for production
- Enable key rotation

### IAM Roles
- Follow least privilege principle
- Use separate roles for different purposes
- Enable MFA for sensitive operations

### Network Security
- Use private subnets for EKS nodes
- Restrict security group rules
- Enable VPC flow logs

### EKS Security
- Use API_AND_CONFIG_MAP authentication mode
- Enable IAM Access Entries
- Restrict public endpoint access
- Enable secrets encryption

---

## 📝 Customization

### Extending Modules

To add features to a module:

1. Add variables in `variables.tf`
2. Implement in `main.tf`
3. Add outputs in `outputs.tf`
4. Update module README
5. Test thoroughly

### Creating New Modules

Follow the module structure:

```bash
mkdir modules/new-module
cd modules/new-module
touch main.tf variables.tf outputs.tf versions.tf README.md
```

---

## 🔍 Testing

### Validate Syntax
```bash
terraform fmt -check -recursive modules/
terraform validate
```

### Plan Changes
```bash
cd EKS-Infra-1  # or EKS-Infra-2
terraform plan
```

### Check Outputs
```bash
terraform output
```

---

## 📚 Related Documentation

- **Main README**: `../README.md`
- **Lab1**: `../EKS-Infra-1/README.md`
- **Lab2**: `../EKS-Infra-2/README.md`
- **IAM Guide**: `../IAM-ACCESS-ENTRIES.md`

---

## ✅ Summary

- ✅ **5 production-ready modules**
- ✅ **VPC, KMS, IAM, EKS, ECR**
- ✅ **IAM Access Entries support**
- ✅ **Security best practices**
- ✅ **Comprehensive outputs**
- ✅ **Reusable across projects**

**Ready to use!** 🚀

