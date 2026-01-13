# ========================================
# LOCAL VALUES
# ========================================

locals {
  # Computed repository list with name prefix
  repositories = [for suffix in var.repository_suffixes : "${var.name_prefix}-${suffix}"]

  # Common tags for all resources
  common_tags = merge(
    var.tags,
    {
      Module     = "ECR"
      ManagedBy  = "Terraform"
      product_id = var.product_id
      used_for   = var.used_for
    }
  )

  # Current AWS account ID
  account_id = data.aws_caller_identity.current.account_id

  # Current AWS region
  region = data.aws_region.current.id
}

