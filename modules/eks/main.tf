########################
# IAM ROLE – CLUSTER   #
########################

resource "aws_iam_role" "cluster" {
  count = var.create_iam_roles ? 1 : 0
  name  = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    "Name" = "${var.cluster_name}-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  count      = var.create_iam_roles ? 1 : 0
  role       = aws_iam_role.cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  count      = var.create_iam_roles ? 1 : 0
  role       = aws_iam_role.cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

########################
# IAM ROLE – NODES     #
########################

resource "aws_iam_role" "node_group" {
  count = var.create_iam_roles ? 1 : 0
  name  = "${var.cluster_name}-nodegroup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    "Name" = "${var.cluster_name}-nodegroup-role"
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  count      = var.create_iam_roles ? 1 : 0
  role       = aws_iam_role.node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  count      = var.create_iam_roles ? 1 : 0
  role       = aws_iam_role.node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  count      = var.create_iam_roles ? 1 : 0
  role       = aws_iam_role.node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

########################
# SECURITY GROUP       #
########################

resource "aws_security_group" "cluster" {
  count       = var.create_cluster_security_group ? 1 : 0
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  # User-defined ingress rules (CIDR-based)
  dynamic "ingress" {
    for_each = var.cluster_security_group_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # Additional rules with SG-to-SG and self support
  dynamic "ingress" {
    for_each = var.cluster_security_group_additional_rules
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = length(ingress.value.cidr_blocks) > 0 ? ingress.value.cidr_blocks : null
      security_groups = length(ingress.value.security_groups) > 0 ? ingress.value.security_groups : null
      self            = ingress.value.self
    }
  }

  # Controlled egress rules (when allow_all_cluster_egress is false)
  dynamic "egress" {
    for_each = var.allow_all_cluster_egress ? [] : var.cluster_security_group_egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  # Allow all egress only if explicitly enabled
  dynamic "egress" {
    for_each = var.allow_all_cluster_egress ? [1] : []
    content {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = merge(var.tags, {
    "Name" = "${var.cluster_name}-cluster-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

########################
# EKS CLUSTER          #
########################

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.create_iam_roles ? aws_iam_role.cluster[0].arn : var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.enable_private_access
    endpoint_public_access  = var.enable_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [local.cluster_security_group_id_effective]
  }

  # Access configuration - Required for Auto Mode
  access_config {
    authentication_mode                         = var.enable_auto_mode ? "API_AND_CONFIG_MAP" : "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Bootstrap configuration - Must be false for Auto Mode
  bootstrap_self_managed_addons = var.enable_auto_mode ? false : true

  # EKS Auto Mode configuration
  # Note: All three configs (compute, networking, storage) must be set together
  dynamic "compute_config" {
    for_each = var.enable_auto_mode ? [1] : []
    content {
      enabled       = true
      node_pools    = ["general-purpose", "system"]
      node_role_arn = var.create_iam_roles ? aws_iam_role.node_group[0].arn : var.node_role_arn
    }
  }

  dynamic "kubernetes_network_config" {
    for_each = var.enable_auto_mode ? [1] : []
    content {
      elastic_load_balancing {
        enabled = true
      }
    }
  }

  dynamic "storage_config" {
    for_each = var.enable_auto_mode ? [1] : []
    content {
      block_storage {
        enabled = true
      }
    }
  }

  dynamic "encryption_config" {
    for_each = var.kms_key_arn != "" ? [1] : []
    content {
      resources = ["secrets"]

      provider {
        key_arn = var.kms_key_arn
      }
    }
  }

  tags = var.tags

  # Note: Dependencies are handled implicitly through role_arn reference
  # When create_iam_roles=true, role_arn references aws_iam_role.cluster[0].arn
  # This creates automatic dependency on the role and its policy attachments
}

########################
# EKS MANAGED NODEGROUP
########################
# Note: Node groups are not created when Auto Mode is enabled

resource "aws_eks_node_group" "default" {
  count = var.enable_auto_mode ? 0 : 1

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-default-ng"
  node_role_arn   = var.create_iam_roles ? aws_iam_role.node_group[0].arn : var.node_role_arn

  subnet_ids = var.private_subnet_ids

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  instance_types = var.node_group_instance_types
  capacity_type  = var.node_group_capacity_type
  disk_size      = var.node_group_disk_size

  labels = var.node_group_labels

  tags = merge(var.tags, var.node_group_tags)

  lifecycle {
    create_before_destroy = true
  }

  # Note: Dependencies are handled implicitly through node_role_arn reference
  # When create_iam_roles=true, node_role_arn references aws_iam_role.node_group[0].arn
  # This creates automatic dependency on the role and its policy attachments
}

########################
# OIDC PROVIDER (IRSA) #
########################

resource "aws_iam_openid_connect_provider" "cluster" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [var.oidc_thumbprint]
}

########################
# IAM FOR EBS CSI      #
########################
# Note: Not needed when Auto Mode is enabled (AWS manages addons)

resource "aws_iam_role" "ebs_csi" {
  count = var.enable_auto_mode ? 0 : 1
  name  = "${var.cluster_name}-ebs-csi-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_issuer_without_https}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    "Name" = "${var.cluster_name}-ebs-csi-irsa"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count      = var.enable_auto_mode ? 0 : 1
  role       = aws_iam_role.ebs_csi[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

########################
# EKS ADDONS           #
########################
# Note: Addons are not manually managed when Auto Mode is enabled

resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_auto_mode ? 0 : 1

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "ebs_csi" {
  count = var.enable_auto_mode ? 0 : 1

  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi[0].arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi[0]
  ]
}