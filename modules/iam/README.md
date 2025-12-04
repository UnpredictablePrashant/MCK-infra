# IAM Module

This module creates IAM roles and policies for EKS cluster and node groups with comprehensive permissions for KMS encryption, VPC management, and AWS service integration.

## Features

- **EKS Cluster IAM Role**: Service role for EKS control plane
- **EKS Node IAM Role**: Service role for EKS worker nodes
- **KMS Permissions**: Integrated policies for encryption at rest
- **VPC/Networking Permissions**: Enhanced networking capabilities
- **Auto Scaling Support**: Permissions for cluster autoscaler
- **Instance Profile**: EC2 instance profile for node groups

## Resources Created

### EKS Cluster Role
- IAM role with EKS service principal
- AmazonEKSClusterPolicy (AWS managed)
- Custom KMS encryption policy
- Custom VPC resource management policy

### EKS Node Role
- IAM role with EC2 service principal
- AmazonEKSWorkerNodePolicy (AWS managed)
- AmazonEKS_CNI_Policy (AWS managed)
- AmazonEC2ContainerRegistryReadOnly (AWS managed)
- Custom KMS decryption policy
- Custom VPC and Auto Scaling policy
- EC2 instance profile for node attachment

## Usage

```hcl
module "iam" {
  source = "./modules/iam"

  project_name               = "my-project"
  environment                = "production"
  region                     = "us-east-1"
  cluster_name               = "my-eks-cluster"
  cluster_role_name          = "my-eks-cluster-role"
  node_role_name             = "my-eks-node-role"
  node_instance_profile_name = "my-eks-node-profile"
  iam_role_path              = "/"

  tags = {
    Project     = "MyProject"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_name` | Project name for resource naming | `string` | `"eks"` | no |
| `environment` | Environment name (e.g., dev, staging, production) | `string` | `"production"` | no |
| `region` | AWS region | `string` | `"us-east-1"` | no |
| `cluster_name` | Name of the EKS cluster | `string` | `"eks-cluster"` | no |
| `cluster_role_name` | Name of the EKS cluster IAM role | `string` | `"eks-cluster-role"` | no |
| `node_role_name` | Name of the EKS node IAM role | `string` | `"eks-node-role"` | no |
| `node_instance_profile_name` | Name of the EKS node instance profile | `string` | `"eks-node-instance-profile"` | no |
| `iam_role_path` | Path for IAM roles | `string` | `"/"` | no |
| `tags` | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `eks_cluster_role_arn` | ARN of the EKS cluster IAM role |
| `eks_cluster_role_name` | Name of the EKS cluster IAM role |
| `eks_node_role_arn` | ARN of the EKS node IAM role |
| `eks_node_role_name` | Name of the EKS node IAM role |
| `eks_node_instance_profile` | Name of the EKS node instance profile |

## IAM Permissions Overview

### Cluster Role Permissions
- **EKS Cluster Policy**: Full EKS cluster management
- **KMS Encryption**: Encrypt/decrypt secrets using KMS
- **VPC Management**: Create and manage security groups, ENIs
- **Networking**: Manage VPC resources for cluster operations

### Node Role Permissions
- **Worker Node Policy**: Core EKS node functionality
- **CNI Policy**: VPC CNI plugin for pod networking
- **ECR Access**: Pull container images from ECR
- **KMS Decryption**: Decrypt encrypted secrets and volumes
- **Auto Scaling**: Describe ASG and EC2 resources
- **VPC Read Access**: Describe VPC resources

## Security Considerations

1. **Least Privilege**: Policies follow AWS best practices
2. **KMS Scope**: KMS permissions scoped via service conditions
3. **Service Principals**: Proper trust relationships for EKS and EC2
4. **Resource Tagging**: All roles tagged for audit and tracking
5. **Path Isolation**: Optional IAM path for organizational separation

## Integration with Other Modules

This IAM module is designed to work with:
- **KMS Module**: For encryption key permissions
- **EKS Module**: Provides required roles for cluster and nodes
- **VPC Module**: Network permissions aligned with VPC resources

## Example: Using with EKS Module

```hcl
module "iam" {
  source = "./modules/iam"
  
  cluster_name      = "prod-eks"
  cluster_role_name = "prod-eks-cluster-role"
  node_role_name    = "prod-eks-node-role"
  
  tags = local.common_tags
}

module "eks" {
  source = "./modules/eks"
  
  cluster_name     = "prod-eks"
  create_iam_roles = false
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn
  
  # ... other EKS config
}
```

## Additional Policies

### Cluster KMS Policy
Allows EKS cluster to:
- Decrypt secrets
- Generate data keys
- Describe keys
- Create grants for persistent volumes

### Node KMS Policy
Allows worker nodes to:
- Decrypt encrypted EBS volumes
- Read encrypted secrets
- Access KMS-encrypted data

### VPC Policies
Comprehensive networking permissions for:
- Security group management
- ENI lifecycle management
- Route table operations
- VPC resource discovery

## Compliance

This module creates IAM roles that align with:
- AWS Well-Architected Framework
- CIS AWS Foundations Benchmark
- SOC 2 compliance requirements
- HIPAA technical safeguards

## Version Requirements

- Terraform >= 1.9
- AWS Provider >= 5.23

## Author

Generated for MCK Infrastructure Project

## License

Internal use only

