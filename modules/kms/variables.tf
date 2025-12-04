
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