# KMS Key for EKS Cluster Encryption

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



