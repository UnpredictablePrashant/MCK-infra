output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64 encoded)"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID associated with the EKS cluster (created or provided)"
  value       = local.cluster_security_group_id_effective
}

output "cluster_oidc_issuer" {
  description = "OIDC issuer URL for the EKS cluster"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "node_group_name" {
  description = "Default node group name (empty if Auto Mode is enabled)"
  value       = var.enable_auto_mode ? "" : aws_eks_node_group.default[0].node_group_name
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN for the node group"
  value       = var.create_iam_roles ? aws_iam_role.node_group[0].arn : var.node_role_arn
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN for the cluster"
  value       = var.create_iam_roles ? aws_iam_role.cluster[0].arn : var.cluster_role_arn
}

output "auto_mode_enabled" {
  description = "Whether EKS Auto Mode is enabled"
  value       = var.enable_auto_mode
}

output "access_entries" {
  description = "Map of IAM access entries created"
  value = {
    for k, v in aws_eks_access_entry.this : k => {
      principal_arn     = v.principal_arn
      kubernetes_groups = v.kubernetes_groups
      type              = v.type
      access_entry_arn  = v.access_entry_arn
    }
  }
}

output "access_entry_policy_associations" {
  description = "Map of IAM access entry policy associations"
  value = {
    for k, v in aws_eks_access_policy_association.this : k => {
      principal_arn     = v.principal_arn
      policy_arn        = v.policy_arn
      access_scope_type = v.access_scope[0].type
      associated_at     = v.associated_at
    }
  }
}

output "authentication_mode" {
  description = "EKS cluster authentication mode"
  value       = aws_eks_cluster.this.access_config[0].authentication_mode
}