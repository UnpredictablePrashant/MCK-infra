# ECR Module

This Terraform module manages AWS Elastic Container Registry (ECR) repositories with support for encryption, lifecycle policies, access control, and image scanning.

## Features

- **Multi-Repository Support**: Create single or multiple ECR repositories
- **KMS Encryption**: Optional KMS-based encryption for repositories
- **Image Scanning**: Automatic vulnerability scanning on image push
- **Lifecycle Policies**: Automatic cleanup of old/untagged images
- **Access Control**: Fine-grained repository and registry-level IAM policies
- **Tag Mutability**: Control whether image tags can be overwritten
- **Public Repositories**: Optional public ECR repository support
- **Cross-Account Access**: Support for multi-account deployments

## Usage

### Basic Single Repository

```hcl
module "ecr" {
  source = "./modules/ecr"

  repository_name     = "my-app"
  environment         = "production"
  project_name        = "my-project"
  scan_on_push        = true
  image_tag_mutability = "IMMUTABLE"
}
```

### Multiple Repositories

```hcl
module "ecr" {
  source = "./modules/ecr"

  repository_names = [
    "api-service",
    "web-service",
    "worker-service"
  ]
  
  environment  = "production"
  project_name = "my-project"
}
```

### With KMS Encryption

```hcl
module "ecr" {
  source = "./modules/ecr"

  repository_names    = ["my-app"]
  enable_encryption   = true
  kms_key_id          = aws_kms_key.ecr.id
  environment         = "production"
}
```

### With Repository Policy (Pull Access)

```hcl
module "ecr" {
  source = "./modules/ecr"

  repository_names            = ["my-app"]
  enable_repository_policy    = true
  repository_policy_principals = [
    "arn:aws:iam::123456789012:role/eks-node-role",
    "arn:aws:iam::123456789012:user/developer"
  ]
}
```

### With Read-Write Access

```hcl
module "ecr" {
  source = "./modules/ecr"

  repository_names                   = ["my-app"]
  enable_repository_read_write_policy = true
  repository_read_write_principals   = [
    "arn:aws:iam::123456789012:role/ci-cd-role"
  ]
}
```

### Complete Configuration

```hcl
module "ecr" {
  source = "./modules/ecr"

  # Repository Configuration
  repository_names     = ["api", "web", "worker"]
  image_tag_mutability = "IMMUTABLE"
  
  # Image Management
  scan_on_push              = true
  enable_lifecycle_policy   = true
  image_expiration_days     = 7
  max_image_count           = 10
  
  # Security & Encryption
  enable_encryption       = true
  kms_key_id              = aws_kms_key.ecr.id
  
  # Access Control
  enable_repository_policy          = true
  repository_policy_principals      = ["arn:aws:iam::123456789012:role/eks-node-role"]
  enable_repository_read_write_policy = true
  repository_read_write_principals  = ["arn:aws:iam::123456789012:role/ci-cd-role"]
  
  # Tagging
  environment = "production"
  project_name = "my-project"
  tags = {
    ManagedBy = "Terraform"
    CostCenter = "Engineering"
  }
}
```

## Inputs

### Required
- **repository_name**: Single repository name (used if `repository_names` is empty)

### Optional
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `repository_names` | `list(string)` | `[]` | List of ECR repository names |
| `image_tag_mutability` | `string` | `MUTABLE` | Tag mutability (MUTABLE or IMMUTABLE) |
| `scan_on_push` | `bool` | `true` | Enable image scanning on push |
| `image_expiration_days` | `number` | `7` | Days to keep untagged images |
| `enable_lifecycle_policy` | `bool` | `true` | Enable automatic image cleanup |
| `max_image_count` | `number` | `10` | Max number of images to retain |
| `enable_encryption` | `bool` | `true` | Enable KMS encryption |
| `kms_key_id` | `string` | `""` | KMS key ID for encryption |
| `enable_repository_policy` | `bool` | `false` | Enable repo read policy |
| `repository_policy_principals` | `list(string)` | `[]` | Principals allowed to pull |
| `enable_repository_read_write_policy` | `bool` | `false` | Enable repo read-write policy |
| `repository_read_write_principals` | `list(string)` | `[]` | Principals allowed read/write |
| `enable_registry_policy` | `bool` | `false` | Enable registry-wide policy |
| `registry_policy_principals` | `list(string)` | `[]` | Registry policy principals |
| `environment` | `string` | `production` | Environment name |
| `project_name` | `string` | `my-project` | Project name for tagging |
| `tags` | `map(string)` | `{}` | Additional tags |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `repository_urls` | `map(string)` | URLs of ECR repositories |
| `repository_arns` | `map(string)` | ARNs of ECR repositories |
| `repository_names` | `map(string)` | Names of ECR repositories |
| `repository_registry_id` | `map(string)` | Registry IDs |
| `docker_login_commands` | `map(string)` | Docker login commands |
| `public_repositories` | `map(string)` | Public repository URIs |
| `lifecycle_policies` | `map(string)` | Applied lifecycle policies |

## Lifecycle Policy Details

The module applies two lifecycle rules to manage images:

1. **Untagged Image Cleanup**: Automatically deletes untagged images older than `image_expiration_days`
2. **Tagged Image Retention**: Keeps only the most recent `max_image_count` tagged images

Example:
- If `image_expiration_days = 7` and `max_image_count = 10`
- Untagged images older than 7 days are deleted
- More than 10 tagged images trigger deletion of oldest ones

## Security Best Practices

1. **Enable KMS Encryption**
   ```hcl
   enable_encryption = true
   kms_key_id = aws_kms_key.ecr.id
   ```

2. **Use Immutable Tags**
   ```hcl
   image_tag_mutability = "IMMUTABLE"
   ```

3. **Enable Image Scanning**
   ```hcl
   scan_on_push = true
   ```

4. **Restrict Access**
   - Only grant pull access to EKS nodes
   - Only grant push access to CI/CD pipelines
   ```hcl
   enable_repository_policy = true
   repository_policy_principals = ["arn:aws:iam::ACCOUNT:role/eks-node-role"]
   ```

5. **Regular Image Cleanup**
   ```hcl
   enable_lifecycle_policy = true
   image_expiration_days = 7
   max_image_count = 10
   ```

## Docker Login

The module outputs Docker login commands for easy authentication:

```bash
$(terraform output -raw docker_login_commands | jq -r '.my-app')
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

## Cross-Account Access

To allow another AWS account to pull images:

```hcl
enable_repository_policy = true
repository_policy_principals = [
  "arn:aws:iam::111111111111:root"  # External account ID
]
```

## Monitoring & Logs

ECR automatically logs to CloudWatch. Enable enhanced monitoring:

```bash
aws ecr describe-image-scan-findings \
  --repository-name my-app \
  --image-id imageTag=latest
```

## Cost Optimization

1. **Delete Untagged Images**: Reduces storage costs
2. **Limit Image Count**: Prevents unnecessary retention
3. **Use Lifecycle Policies**: Automates cleanup
4. **Image Compression**: Use alpine/slim base images

## Troubleshooting

### Images not scanning
- Ensure `scan_on_push = true`
- Check ECR permissions
- Verify KMS key permissions

### Access denied errors
- Review repository policies
- Check IAM role permissions
- Verify principal ARNs

### Lifecycle policy not working
- Ensure `enable_lifecycle_policy = true`
- Check image tags and push dates
- Review lifecycle rule priority

## Examples

See the `examples/` directory for complete working examples:
- `single-repo.tf` - Single repository setup
- `multi-repo.tf` - Multiple repositories
- `with-kms.tf` - KMS encryption
- `with-policies.tf` - Access control policies
- `complete.tf` - Full feature setup
