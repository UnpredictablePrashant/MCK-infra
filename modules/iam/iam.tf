# ========================================
# EKS CLUSTER IAM ROLE & POLICIES
# ========================================

# EKS Cluster Service Role
resource "aws_iam_role" "eks_cluster_role" {
  name               = var.cluster_role_name
  path               = var.iam_role_path
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = var.cluster_role_name
      Environment = var.environment
    }
  )
}

# Attach AWS managed EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# KMS permissions for cluster encryption
resource "aws_iam_policy" "eks_cluster_kms" {
  name        = "${var.cluster_role_name}-kms-policy"
  path        = var.iam_role_path
  description = "Policy for EKS cluster to use KMS for encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow EKS to use KMS for encryption"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "eks.${data.aws_region.current.name}.amazonaws.com"
            ]
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_role_name}-kms-policy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_cluster_kms" {
  policy_arn = aws_iam_policy.eks_cluster_kms.arn
  role       = aws_iam_role.eks_cluster_role.name
}

# VPC and EC2 permissions for cluster networking
resource "aws_iam_policy" "eks_cluster_vpc" {
  name        = "${var.cluster_role_name}-vpc-policy"
  path        = var.iam_role_path
  description = "Policy for EKS cluster to manage VPC and networking resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKS VPC Resource Management"
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeVpcs",
          "ec2:DescribeNetworkInterfaceAttribute",
          "ec2:ModifyNetworkInterfaceAttribute"
        ]
        Resource = "*"
      },
      {
        Sid    = "EKS Elastic Network Interface Management"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_role_name}-vpc-policy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_cluster_vpc" {
  policy_arn = aws_iam_policy.eks_cluster_vpc.arn
  role       = aws_iam_role.eks_cluster_role.name
}

# ========================================
# EKS NODE IAM ROLE & POLICIES
# ========================================

# EKS Node (Worker) IAM Role
resource "aws_iam_role" "eks_node_role" {
  name               = var.node_role_name
  path               = var.iam_role_path
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = var.node_role_name
      Environment = var.environment
    }
  )
}

# Attach AWS managed Node policies
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# KMS permissions for node encryption
resource "aws_iam_policy" "eks_node_kms" {
  name        = "${var.node_role_name}-kms-policy"
  path        = var.iam_role_path
  description = "Policy for EKS nodes to use KMS for encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow EKS nodes to decrypt with KMS"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.node_role_name}-kms-policy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_node_kms" {
  policy_arn = aws_iam_policy.eks_node_kms.arn
  role       = aws_iam_role.eks_node_role.name
}

# VPC and networking permissions for nodes
resource "aws_iam_policy" "eks_node_vpc" {
  name        = "${var.node_role_name}-vpc-policy"
  path        = var.iam_role_path
  description = "Policy for EKS nodes to manage VPC and networking"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKS Node VPC and EC2 Permissions"
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeVpcs",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaceAttribute",
          "ec2:DescribeImages"
        ]
        Resource = "*"
      },
      {
        Sid    = "EKS Node Auto Scaling"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeSpotPriceHistory"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.node_role_name}-vpc-policy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_node_vpc" {
  policy_arn = aws_iam_policy.eks_node_vpc.arn
  role       = aws_iam_role.eks_node_role.name
}

# Instance Profile for EKS Nodes
resource "aws_iam_instance_profile" "eks_node" {
  name = var.node_instance_profile_name
  role = aws_iam_role.eks_node_role.name
}


