# ========================================
# ECR OUTPUTS
# ========================================

output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for name, repo in aws_ecr_repository.this :
    name => repo.repository_url
  }
}

output "repository_arns" {
  description = "ARNs of the ECR repositories"
  value = {
    for name, repo in aws_ecr_repository.this :
    name => repo.arn
  }
}

output "repository_names" {
  description = "Names of the ECR repositories"
  value = {
    for name, repo in aws_ecr_repository.this :
    name => repo.name
  }
}

output "repository_registry_id" {
  description = "The registry ID where the repository is stored"
  value = {
    for name, repo in aws_ecr_repository.this :
    name => repo.registry_id
  }
}

output "all_repositories" {
  description = "Complete ECR repository objects"
  value       = aws_ecr_repository.this
  sensitive   = false
}

output "lifecycle_policies" {
  description = "Applied lifecycle policies"
  value = {
    for name, policy in aws_ecr_lifecycle_policy.this :
    name => policy.policy
  }
}

# Docker login command helper
output "docker_login_commands" {
  description = "Docker login commands for each repository region"
  value = {
    for name, repo in aws_ecr_repository.this :
    name => "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${repo.repository_url}"
  }
}
