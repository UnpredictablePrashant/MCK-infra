output "vpc_id" {
  value       = local.vpc_id
  description = "ID of the VPC"
}

output "public_subnet_ids" {
  value       = [for s in aws_subnet.public : s.id]
  description = "IDs of public subnets"
}

output "private_subnet_ids" {
  value       = [for s in aws_subnet.private : s.id]
  description = "IDs of private subnets"
}

output "internet_gateway_id" {
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null
  description = "Internet Gateway ID (if created)"
}

output "nat_gateway_id" {
  value       = length(aws_nat_gateway.this) > 0 ? aws_nat_gateway.this[0].id : null
  description = "NAT Gateway ID (if created)"
}

output "public_route_table_id" {
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
  description = "Public route table ID (if created)"
}

output "private_route_table_id" {
  value       = length(aws_route_table.private) > 0 ? aws_route_table.private[0].id : null
  description = "Private route table ID (if created)"
}

output "security_group_id" {
  value       = length(aws_security_group.default) > 0 ? aws_security_group.default[0].id : null
  description = "Security group ID (if created)"
}

output "security_group_arn" {
  value       = length(aws_security_group.default) > 0 ? aws_security_group.default[0].arn : null
  description = "Security group ARN (if created)"
}

output "security_group_name" {
  value       = length(aws_security_group.default) > 0 ? aws_security_group.default[0].name : null
  description = "Security group name (if created)"
}

output "security_group_vpc_id" {
  value       = length(aws_security_group.default) > 0 ? aws_security_group.default[0].vpc_id : null
  description = "VPC ID associated with the security group"
}

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster_role.name
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.eks_node_role.arn
}

output "eks_node_role_name" {
  description = "Name of the EKS node IAM role"
  value       = aws_iam_role.eks_node_role.name
}

output "eks_node_instance_profile" {
  description = "Name of the EKS node instance profile"
  value       = aws_iam_instance_profile.eks_node.name
}

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