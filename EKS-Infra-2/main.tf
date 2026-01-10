########################################
# Local Values
########################################

locals {
  name_prefix = "mck-dev-lab2"
  product_id  = "00000"
  used_for    = "non-prod"

  common_tags = {
    Project     = "mck"
    Environment = "dev-lab2"
    ManagedBy   = "Terraform"
  }
}

########################################
# VPC Module
#########################################

module "vpc" {
  source = "../modules/vpc"

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

  # Mandatory tags
  product_id = local.product_id
  used_for   = local.used_for

  tags = local.common_tags
}

########################################
# KMS Module
########################################

module "kms" {
  source = "../modules/kms"

  project_name             = "mck"
  environment              = "dev"
  kms_key_description      = "KMS key for MCK EKS cluster encryption"
  kms_alias_name           = "mck-dev-eks-encryption"
  kms_deletion_window_days = 10
  kms_enable_key_rotation  = true

  # Mandatory tags
  product_id = local.product_id
  used_for   = local.used_for

  tags = local.common_tags
}

########################################
# IAM Module
########################################

module "iam" {
  source = "../modules/iam"

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

  # Mandatory tags
  product_id = local.product_id
  used_for   = local.used_for

  tags = local.common_tags
}

########################################
# EKS Module
########################################

module "eks" {
  source = "../modules/eks"

  depends_on = [module.vpc, module.iam, module.kms]

  region          = "us-east-1"
  cluster_name    = "${local.name_prefix}-eks"
  cluster_version = "1.34"

  # Network configuration from VPC module
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Use IAM roles from IAM module
  create_iam_roles = false
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn

  # KMS Encryption - use KMS key from KMS module
  kms_key_arn = module.kms.kms_key_arn

  # EKS Auto Mode - Automated node provisioning and management
  # Set to true to enable Auto Mode (requires K8s 1.31+)
  # When enabled:
  # - Node group settings below are ignored
  # - Authentication mode automatically set to API_AND_CONFIG_MAP
  # - Compute, networking, and storage are fully managed by AWS
  # WARNING: Enabling Auto Mode on existing cluster requires cluster recreation
  enable_auto_mode = false

  # Authentication mode - API_AND_CONFIG_MAP allows both EKS API and aws-auth ConfigMap
  # This is recommended for managing access to the cluster
  # Valid options: CONFIG_MAP, API, API_AND_CONFIG_MAP
  authentication_mode = "API_AND_CONFIG_MAP"

  # IAM Access Entries - Manage cluster access via AWS IAM
  # Only works with API or API_AND_CONFIG_MAP authentication mode
  enable_iam_access_entries      = true
  create_standard_access_entries = true # Automatically creates EC2_LINUX access entry for node role

  # Custom IAM Access Entries
  # Add IAM users or roles that need cluster access
  # Note: 
  # - AWS Service Linked Roles are automatically managed by AWS (don't add manually)
  # - Cluster creator (Infra-lab-EKS) is automatically added with bootstrap_cluster_creator_admin_permissions = true
  # - Node role access is automatically configured when using create_standard_access_entries = true
  access_entries = {
    # Admin role with full cluster access
    "arn:aws:iam::0123456789012:role/admin" = {
      kubernetes_groups = []
      type              = "STANDARD"
    }

    # Additional custom roles can be added here
    # Example:
    # "arn:aws:iam::0123456789012:role/developer" = {
    #   kubernetes_groups = []
    #   type              = "STANDARD"
    # }
  }

  # IAM Access Entry Policy Associations
  # Associate AWS managed EKS policies with IAM principals
  # Note: 
  # - AWS Service Linked Roles cannot have policy associations added via Terraform
  # - Cluster creator (Infra-lab-EKS) automatically gets full access via bootstrap_cluster_creator_admin_permissions
  access_entry_policy_associations = {
    # Admin role - Full cluster admin access
    "admin-cluster-admin" = {
      principal_arn = "arn:aws:iam::0123456789012:role/admin"
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = {
        type = "cluster"
      }
    }

    "admin-admin-policy" = {
      principal_arn = "arn:aws:iam::0123456789012:role/admin"
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
      access_scope = {
        type = "cluster"
      }
    }

    "admin-admin-view-policy" = {
      principal_arn = "arn:aws:iam::0123456789012:role/admin"
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
      access_scope = {
        type = "cluster"
      }
    }
  }

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
      description     = "Allow nodes to communicate with control plane"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      self            = true
      cidr_blocks     = []
      security_groups = []
    },
    {
      description     = "Allow control plane to communicate with nodes (kubelet)"
      from_port       = 10250
      to_port         = 10250
      protocol        = "tcp"
      cidr_blocks     = ["10.0.10.0/24", "10.0.11.0/24"] # Private subnets
      security_groups = []
      self            = false
    },
    {
      description     = "ArgoCD HTTP/gRPC access from VPC"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = ["10.0.0.0/16"] # VPC CIDR for internal access
      security_groups = []
      self            = false
    },
    {
      description     = "ArgoCD alternative HTTP port from VPC"
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      cidr_blocks     = ["10.0.0.0/16"] # VPC CIDR for internal access
      security_groups = []
      self            = false
    },
    # Public access rules for ArgoCD UI - REPLACE 0.0.0.0/0 WITH YOUR PUBLIC IP/32
    {
      description     = "ArgoCD UI public access (HTTP) - UPDATE WITH YOUR IP"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = ["0.0.0.0/0"] # TODO: Replace with your IP (e.g., "203.0.113.45/32")
      security_groups = []
      self            = false
    },
    {
      description     = "ArgoCD UI public access (HTTPS on 8080) - UPDATE WITH YOUR IP"
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      cidr_blocks     = ["0.0.0.0/0"] # TODO: Replace with your IP (e.g., "203.0.113.45/32")
      security_groups = []
      self            = false
    }
  ]

  # Enable egress for ArgoCD to access Git repos, container registries, and external APIs
  allow_all_cluster_egress = true

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

  # Mandatory tags
  product_id = local.product_id
  used_for   = local.used_for

  tags = local.common_tags
}
########################################
# ECR Module
########################################

module "ecr" {
  source = "../modules/ecr"

  depends_on = [module.kms]

  project_name            = "mck"
  environment             = "dev"
  repository_names        = ["mck-app", "mck-api", "mck-worker"]
  image_tag_mutability    = "MUTABLE"
  scan_on_push            = true
  enable_encryption       = true
  kms_key_id              = module.kms.kms_key_id
  enable_lifecycle_policy = true
  image_expiration_days   = 7
  max_image_count         = 10

  # Mandatory tags
  product_id = local.product_id
  used_for   = local.used_for

  tags = local.common_tags
}