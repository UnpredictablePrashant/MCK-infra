

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

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "iam_role_path" {
  description = "Path for IAM roles"
  type        = string
  default     = "/"
}

variable "product_id" {
  description = "Product ID tag for resource tracking"
  type        = string
}

variable "used_for" {
  description = "Used for tag to identify resource purpose (e.g., prod, non-prod)"
  type        = string
}
