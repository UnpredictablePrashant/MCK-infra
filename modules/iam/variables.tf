

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
