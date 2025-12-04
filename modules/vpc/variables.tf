variable "name" {
  description = "Name prefix for VPC and related resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of AZs to use"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDRs (should match azs length if enabled)"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of private subnet CIDRs (should match azs length if enabled)"
  type        = list(string)
  default     = []
}

# Toggles
variable "enable_vpc" {
  description = "Create VPC and all dependent resources"
  type        = bool
  default     = true
}

variable "enable_internet_gateway" {
  description = "Create Internet Gateway and attach to VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Create a single NAT Gateway in the first public subnet"
  type        = bool
  default     = false
}

variable "enable_route_tables" {
  description = "Create public and private route tables"
  type        = bool
  default     = true
}

variable "enable_security_group" {
  description = "Create a default security group with basic rules"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name for the security group (uses var.name if not specified)"
  type        = string
  default     = ""
}

variable "security_group_description" {
  description = "Description for the security group"
  type        = string
  default     = "Managed by Terraform"
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups  = optional(list(string), [])
    self             = optional(bool, false)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      !(rule.from_port == 22 && contains(rule.cidr_blocks, "0.0.0.0/0"))
    ])
    error_message = "SSH (port 22) should not be open to 0.0.0.0/0. Restrict to specific CIDR blocks."
  }

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      !(rule.from_port == 3389 && contains(rule.cidr_blocks, "0.0.0.0/0"))
    ])
    error_message = "RDP (port 3389) should not be open to 0.0.0.0/0. Restrict to specific CIDR blocks."
  }

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      !(rule.from_port == 0 && rule.to_port == 0 && rule.protocol == "-1" && contains(rule.cidr_blocks, "0.0.0.0/0"))
    ])
    error_message = "All traffic ingress from 0.0.0.0/0 is not allowed. Specify specific ports and protocols."
  }
}

variable "egress_rules" {
  description = "List of egress rules for the security group"
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups  = optional(list(string), [])
    self             = optional(bool, false)
  }))
  default = [
    {
      description = "Allow HTTPS outbound"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTP outbound"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow DNS outbound"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "allow_all_egress" {
  description = "Allow all outbound traffic (overrides egress_rules if true)"
  type        = bool
  default     = false
}

variable "revoke_rules_on_delete" {
  description = "Revoke all security group rules before deleting the group"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "EKS-Infrastructure"
  }
}


variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "eks"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
# ========================================
# KMS VARIABLES
# ========================================

variable "kms_deletion_window_days" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 10
}

variable "kms_enable_key_rotation" {
  description = "Enable automatic key rotation for KMS key"
  type        = bool
  default     = true
}

variable "kms_key_description" {
  description = "Description of the KMS key"
  type        = string
  default     = "KMS key for EKS cluster encryption at rest"
}

variable "kms_alias_name" {
  description = "Name of the KMS key alias"
  type        = string
  default     = "eks-cluster-encryption"
}
# ========================================
# EKS CLUSTER VARIABLES
# ========================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  description = "List of EKS cluster log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_cluster_encryption" {
  description = "Enable envelope encryption of secrets using KMS"
  type        = bool
  default     = true
}
# ========================================
# IAM ROLE VARIABLES
# ========================================

variable "iam_role_name_prefix" {
  description = "Prefix for IAM role names"
  type        = string
  default     = "eks"
}

variable "cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  type        = string
  default     = "eks-cluster-role"
}

variable "node_role_name" {
  description = "Name of the EKS node IAM role"
  type        = string
  default     = "eks-node-role"
}

variable "node_instance_profile_name" {
  description = "Name of the EKS node instance profile"
  type        = string
  default     = "eks-node-instance-profile"
}

variable "iam_role_path" {
  description = "Path for IAM roles"
  type        = string
  default     = "/"
}

# ========================================
# NODE GROUP VARIABLES
# ========================================

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "eks-node-group"
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

variable "node_instance_types" {
  description = "Instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

variable "node_capacity_type" {
  description = "Capacity type for the node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "enable_ssm_access" {
  description = "Enable SSM access to nodes"
  type        = bool
  default     = true
}

# ========================================
# SECURITY GROUP VARIABLES
# ========================================

variable "cluster_security_group_name" {
  description = "Name of the cluster security group"
  type        = string
  default     = "eks-cluster-sg"
}

variable "node_security_group_name" {
  description = "Name of the node security group"
  type        = string
  default     = "eks-node-sg"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the cluster"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# ========================================
# LOGGING VARIABLES
# ========================================

variable "cloudwatch_log_group_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 7
}

variable "enable_eks_logs" {
  description = "Enable EKS cluster logs to CloudWatch"
  type        = bool
  default     = true
}
