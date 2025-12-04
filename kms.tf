# KMS Key for EKS Cluster Encryption

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create KMS Key for EKS
resource "aws_kms_key" "eks" {
  description             = var.kms_key_description
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = var.kms_enable_key_rotation
  bypass_policy_lockout_safety_check = false

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-kms-key"
      Environment = var.environment
      Purpose     = "EKS-Encryption"
    }
  )
}

# Create KMS Key Alias for easier reference
resource "aws_kms_alias" "eks" {
  name          = "alias/${var.kms_alias_name}"
  target_key_id = aws_kms_key.eks.key_id
}

# KMS Key Policy for EKS Service
resource "aws_kms_key_policy" "eks" {
  key_id = aws_kms_key.eks.id
  policy = data.aws_iam_policy_document.eks_kms_policy.json
}

# IAM Policy Document for KMS Key
data "aws_iam_policy_document" "eks_kms_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow EKS Service"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow EC2 Service"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow EKS Cluster to use KMS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.eks_cluster_role.arn]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow EKS Nodes to use KMS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.eks_node_role.arn]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Output the KMS Key ID and ARN for reference
output "kms_key_id" {
  description = "The ID of the KMS key for EKS"
  value       = aws_kms_key.eks.id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key for EKS"
  value       = aws_kms_key.eks.arn
}

output "kms_alias" {
  description = "The alias of the KMS key for EKS"
  value       = aws_kms_alias.eks.name
}