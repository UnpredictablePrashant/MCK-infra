# ========================================
# ECR MODULE VARIABLES
# ========================================

variable "repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = []
}

variable "repository_name" {
  description = "Single ECR repository name (used if repository_names is empty)"
  type        = string
  default     = "my-app"
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Indicate whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "image_expiration_days" {
  description = "Number of days to keep untagged images before expiration"
  type        = number
  default     = 7

  validation {
    condition     = var.image_expiration_days > 0
    error_message = "image_expiration_days must be greater than 0."
  }
}

variable "enable_lifecycle_policy" {
  description = "Enable image lifecycle policy to automatically delete old untagged images"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Maximum number of images to keep in the repository"
  type        = number
  default     = 10

  validation {
    condition     = var.max_image_count > 0
    error_message = "max_image_count must be greater than 0."
  }
}

variable "enable_encryption" {
  description = "Enable KMS encryption for ECR repository"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for ECR repository encryption (required if enable_encryption is true)"
  type        = string
  default     = ""
}

variable "enable_repository_read_write_policy" {
  description = "Enable read-write access for specified principals"
  type        = bool
  default     = false
}

variable "repository_read_write_principals" {
  description = "List of AWS principals allowed read/write access to repositories"
  type        = list(string)
  default     = []
}

variable "enable_repository_policy" {
  description = "Enable individual repository permissions policy"
  type        = bool
  default     = false
}

variable "repository_policy_principals" {
  description = "List of AWS principals allowed to pull images from repositories"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "my-project"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Module    = "ECR"
  }
}
