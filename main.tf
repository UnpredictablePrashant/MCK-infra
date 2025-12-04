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
# KMS Module
########################################

module "kms" {
  source = "./modules/kms"

  project_name                = "mck"
  environment                 = "dev"
  kms_key_description         = "KMS key for MCK EKS cluster encryption"
  kms_alias_name              = "mck-dev-eks-encryption"
  kms_deletion_window_days    = 10
  kms_enable_key_rotation     = true

  tags = local.common_tags
}

########################################
# IAM Module
########################################

module "iam" {
  source = "./modules/iam"

  depends_on = [module.kms]

  project_name               = "mck"
  environment                = "dev"
  region                     = "us-east-1"
  cluster_name               = "${local.name_prefix}-eks"
  cluster_version            = "1.34"
  cluster_role_name          = "${local.name_prefix}-eks-cluster-role"
  node_role_name             = "${local.name_prefix}-eks-node-role"
  node_instance_profile_name = "${local.name_prefix}-eks-node-profile"
  iam_role_path              = "/"

  tags = local.common_tags
}

########################################
# EKS Module
########################################

module "eks" {
  source = "./modules/eks"

  depends_on = [module.vpc, module.iam, module.kms]

  region          = "us-east-1"
  cluster_name    = "${local.name_prefix}-eks"
  cluster_version = "1.34"

  # Network configuration from VPC module
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Use IAM roles from IAM module
  create_iam_roles   = false
  cluster_role_arn   = module.iam.eks_cluster_role_arn
  node_role_arn      = module.iam.eks_node_role_arn

  # KMS Encryption - use KMS key from KMS module
  kms_key_arn = module.kms.kms_key_arn

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
