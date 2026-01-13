
variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "EKS-Infrastructure"
  }
}


variable "name_prefix" {
  description = "Prefix for all resource names (e.g., mck-dev-lab1)"
  type        = string
}

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

variable "product_id" {
  description = "Product ID tag for resource tracking"
  type        = string
}

variable "used_for" {
  description = "Used for tag to identify resource purpose (e.g., prod, non-prod)"
  type        = string
}