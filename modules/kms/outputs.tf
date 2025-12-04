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