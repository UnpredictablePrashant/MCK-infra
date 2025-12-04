# ========================================
# LOCAL VALUES
# ========================================

locals {
  # Computed repository list
  repositories = length(var.repository_names) > 0 ? var.repository_names : [var.repository_name]

  # Common tags for all resources
  common_tags = merge(
    var.tags,
    {
      Module      = "ECR"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )

  # Current AWS account ID
  account_id = data.aws_caller_identity.current.account_id

  # Current AWS region
  region = data.aws_region.current.name
}

