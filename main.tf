########################################
# Terraform & Provider Configuration
########################################

terraform {
  required_version = ">=1.9, <1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.23, <7"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "mck"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

########################################
# Local Values
########################################

locals {
  name_prefix = "mck-dev"

  common_tags = {
    Project     = "mck"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

########################################
# VPC Module
########################################

module "vpc" {
  source = "./modules/vpc"

  name       = local.name_prefix
  cidr_block = "10.0.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  # Feature toggles
  enable_vpc              = true
  enable_internet_gateway = true
  enable_nat_gateway      = true
  enable_route_tables     = true
  enable_security_group   = false

  tags = local.common_tags
}

########################################
# EKS Module
########################################

module "eks" {
  source = "./modules/eks"

  depends_on = [module.vpc]

  region          = "us-east-1"
  cluster_name    = "${local.name_prefix}-eks"
  cluster_version = "1.34"

  # Network configuration from VPC module
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # API access - restrict public access in production
  enable_public_access                 = true
  enable_private_access                = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # TODO: Restrict to your IP in production

  # Security group - restricted to VPC CIDR for security
  create_cluster_security_group = true
  
  # Ingress rules - VPC internal access only (more secure)
  cluster_security_group_ingress_rules = [
    {
      description = "EKS API access from VPC"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR only
    }
  ]

  # Additional rules for node-to-control-plane communication
  cluster_security_group_additional_rules = [
    {
      description = "Allow nodes to communicate with control plane"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      self        = true
    },
    {
      description = "Allow control plane to communicate with nodes (kubelet)"
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      cidr_blocks = ["10.0.10.0/24", "10.0.11.0/24"] # Private subnets
    }
  ]

  # Controlled egress - only allow necessary outbound traffic
  allow_all_cluster_egress = false

  # KMS Encryption (optional) - pass KMS key ARN from KMS module if needed
  # kms_key_arn = module.kms.eks_kms_key_arn

  # Node group configuration
  node_group_min_size       = 2
  node_group_desired_size   = 2
  node_group_max_size       = 4
  node_group_instance_types = ["t3.medium"]
  node_group_capacity_type  = "ON_DEMAND"
  node_group_disk_size      = 20

  node_group_labels = {
    environment = "dev"
  }

  node_group_tags = {
    NodeType = "managed"
  }

  tags = local.common_tags
}

########################################
# Outputs
########################################

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.vpc.nat_gateway_id
}

# EKS Outputs
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS cluster API"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_group_name" {
  description = "Name of the EKS node group"
  value       = module.eks.node_group_name
}

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = module.eks.node_group_iam_role_arn
}

# Kubeconfig helper
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name}"
}
