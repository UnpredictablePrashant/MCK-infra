########################################
# VPC Outputs
########################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.vpc.nat_gateway_id
}

########################################
# KMS Outputs
########################################

output "kms_key_id" {
  description = "The ID of the KMS key for EKS encryption"
  value       = module.kms.kms_key_id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key for EKS encryption"
  value       = module.kms.kms_key_arn
}

output "kms_alias" {
  description = "The alias of the KMS key for EKS"
  value       = module.kms.kms_alias
}

########################################
# IAM Outputs
########################################

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = module.iam.eks_cluster_role_name
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = module.iam.eks_node_role_arn
}

output "eks_node_role_name" {
  description = "Name of the EKS node IAM role"
  value       = module.iam.eks_node_role_name
}

output "eks_node_instance_profile" {
  description = "Name of the EKS node instance profile"
  value       = module.iam.eks_node_instance_profile
}

########################################
# EKS Outputs
########################################

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS cluster API"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_group_name" {
  description = "Name of the EKS node group"
  value       = module.eks.node_group_name
}

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = module.eks.node_group_iam_role_arn
}

########################################
# Helper Outputs
########################################

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name}"
}

