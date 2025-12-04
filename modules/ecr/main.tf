# ========================================
# ECR REPOSITORIES
# ========================================



# Create ECR repositories
resource "aws_ecr_repository" "this" {
  for_each = toset(local.repositories)

  name                       = each.value
  image_tag_mutability       = var.image_tag_mutability
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.enable_encryption ? "KMS" : "AES256"
    kms_key         = var.enable_encryption && var.kms_key_id != "" ? var.kms_key_id : null
  }

  tags = merge(
    var.tags,
    {
      Name        = each.value
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# ========================================
# ECR LIFECYCLE POLICIES
# ========================================

# Lifecycle policy to automatically delete old untagged images
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.enable_lifecycle_policy ? toset(local.repositories) : toset([])

  repository = aws_ecr_repository.this[each.value].name
  policy = jsonencode({
    rules = [
      # Rule 1: Delete untagged images older than specified days
      {
        rulePriority = 1
        description  = "Delete untagged images older than ${var.image_expiration_days} days"
        selection = {
          tagStatus     = "untagged"
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = var.image_expiration_days
        }
        action = {
          type = "expire"
        }
      },
      # Rule 2: Keep only the most recent N images
      {
        rulePriority = 2
        description  = "Keep only the most recent ${var.max_image_count} tagged images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*"]
          countType      = "imageCountMoreThan"
          countNumber    = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  depends_on = [aws_ecr_repository.this]
}

# ========================================
# ECR REPOSITORY POLICIES
# ========================================

# Repository policy for pulling images (read-only)
resource "aws_ecr_repository_policy" "pull" {
  for_each = var.enable_repository_policy && length(var.repository_policy_principals) > 0 ? toset(local.repositories) : toset([])

  repository = aws_ecr_repository.this[each.value].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          AWS = var.repository_policy_principals
        }
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
      }
    ]
  })

  depends_on = [aws_ecr_repository.this]
}

# Repository policy for read-write access
resource "aws_ecr_repository_policy" "read_write" {
  for_each = var.enable_repository_read_write_policy && length(var.repository_read_write_principals) > 0 ? toset(local.repositories) : toset([])

  repository = aws_ecr_repository.this[each.value].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadWrite"
        Effect = "Allow"
        Principal = {
          AWS = var.repository_read_write_principals
        }
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })

  depends_on = [aws_ecr_repository.this]
}
