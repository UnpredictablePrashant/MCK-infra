########################################
# VPC Outputs
########################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways"
  value       = module.vpc.nat_gateway_ids
}

########################################
# KMS Outputs
########################################

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = module.kms.kms_key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = module.kms.kms_key_arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = module.kms.kms_key_alias
}

########################################
# IAM Outputs
########################################

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = module.iam.eks_node_role_arn
}

output "eks_node_instance_profile_name" {
  description = "Name of the EKS node instance profile"
  value       = module.iam.eks_node_instance_profile_name
}

########################################
# EKS Outputs
########################################

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  description = "CA certificate of the EKS cluster"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_cluster_oidc_issuer" {
  description = "OIDC issuer URL of the EKS cluster"
  value       = module.eks.cluster_oidc_issuer
}

output "eks_node_group_name" {
  description = "Name of the EKS node group"
  value       = module.eks.node_group_name
}

output "eks_authentication_mode" {
  description = "Authentication mode of the EKS cluster"
  value       = module.eks.authentication_mode
}

output "eks_access_entries" {
  description = "IAM access entries for the EKS cluster"
  value       = module.eks.access_entries
}

output "eks_access_entry_policy_associations" {
  description = "IAM access entry policy associations"
  value       = module.eks.access_entry_policy_associations
}

########################################
# ECR Outputs
########################################

output "ecr_repository_urls" {
  description = "URLs of ECR repositories"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "ARNs of ECR repositories"
  value       = module.ecr.repository_arns
}

