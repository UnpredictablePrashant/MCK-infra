# KMS Module

This module creates a KMS key for encrypting EKS cluster secrets and EBS volumes with comprehensive key policies for AWS services and IAM principals.

## Features

- **Encryption at Rest**: KMS key for EKS secret encryption
- **Key Rotation**: Automatic annual key rotation
- **Service Access**: Policies for EKS and EC2 services
- **Key Alias**: Human-readable alias for easy reference
- **Compliance Ready**: Meets encryption compliance requirements

## Resources Created

- AWS KMS Key with custom policy
- KMS Key Alias for easy identification
- IAM policy document for multi-service access

## Usage

```hcl
module "kms" {
  source = "./modules/kms"

  project_name             = "my-project"
  environment              = "production"
  kms_key_description      = "KMS key for EKS cluster encryption"
  kms_alias_name           = "my-project-eks-encryption"
  kms_deletion_window_days = 30
  kms_enable_key_rotation  = true

  tags = {
    Project     = "MyProject"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_name` | Project name for resource naming | `string` | `"eks"` | no |
| `environment` | Environment name (e.g., dev, staging, production) | `string` | `"production"` | no |
| `kms_key_description` | Description of the KMS key | `string` | `"KMS key for EKS cluster encryption at rest"` | no |
| `kms_alias_name` | Name of the KMS key alias | `string` | `"eks-cluster-encryption"` | no |
| `kms_deletion_window_days` | KMS key deletion window in days (7-30) | `number` | `10` | no |
| `kms_enable_key_rotation` | Enable automatic key rotation | `bool` | `true` | no |
| `tags` | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `kms_key_id` | The ID of the KMS key |
| `kms_key_arn` | The ARN of the KMS key |
| `kms_alias` | The alias of the KMS key |

## KMS Key Policy

The key policy grants permissions to:

### 1. Root Account Access
- Full KMS administrative access to AWS account root
- Enables IAM policies to control key access

### 2. EKS Service Access
- Decrypt encrypted secrets
- Generate data keys for envelope encryption
- Create grants for persistent volume encryption
- Describe key properties

### 3. EC2 Service Access
- Decrypt EBS volumes
- Generate data keys for volume encryption
- Support for encrypted AMIs

### 4. Cross-Service Encryption
- Allows EKS to create encrypted persistent volumes
- Enables EC2 to launch instances with encrypted volumes
- Supports envelope encryption patterns

## Security Features

### Key Rotation
- Automatic annual rotation enabled by default
- Previous key versions remain active for decryption
- Transparent to applications using the key

### Deletion Protection
- Configurable deletion window (7-30 days)
- Default: 10 days for development
- Recommendation: 30 days for production

### Service Isolation
- Service-specific permissions via principals
- Condition-based access control available
- Audit trail via CloudTrail

## Integration with Other Modules

### With EKS Module
```hcl
module "kms" {
  source = "./modules/kms"
  
  kms_alias_name = "prod-eks-encryption"
  tags           = local.common_tags
}

module "eks" {
  source = "./modules/eks"
  
  cluster_name = "prod-eks"
  kms_key_arn  = module.kms.kms_key_arn
  
  # ... other config
}
```

### With IAM Module
The KMS module works seamlessly with the IAM module, which includes KMS permissions in cluster and node roles.

## Encryption Scope

This KMS key can encrypt:
- **Kubernetes Secrets**: etcd database encryption
- **EBS Volumes**: Node and persistent volume encryption
- **Container Images**: Encrypted ECR repositories (optional)
- **Parameter Store**: Encrypted configuration values
- **Secrets Manager**: Additional secret storage

## Cost Considerations

- **Key Storage**: $1/month per key
- **Requests**: $0.03 per 10,000 requests
- **Rotation**: No additional charge
- **Cross-Region**: Standard AWS data transfer rates

## Compliance Standards

This module supports:
- **HIPAA**: Encryption of PHI at rest
- **PCI DSS**: Cryptographic key management
- **SOC 2**: Encryption controls
- **GDPR**: Data protection requirements
- **FedRAMP**: FIPS 140-2 Level 2 compliance

## Best Practices

### Development Environments
```hcl
kms_deletion_window_days = 10
kms_enable_key_rotation  = false  # Optional: reduce costs
```

### Production Environments
```hcl
kms_deletion_window_days = 30
kms_enable_key_rotation  = true   # Always enabled
```

### Multi-Region Setup
For multi-region clusters, create replica keys:
```hcl
# Primary region
module "kms_primary" {
  source = "./modules/kms"
  providers = { aws = aws.us-east-1 }
}

# Secondary region
module "kms_secondary" {
  source = "./modules/kms"
  providers = { aws = aws.us-west-2 }
}
```

## Monitoring

### CloudWatch Metrics
Key usage metrics available:
- API request count
- Decrypt/encrypt operations
- Grant creation rate

### CloudTrail Events
All KMS operations logged:
- `kms:Decrypt`
- `kms:GenerateDataKey`
- `kms:CreateGrant`
- `kms:DescribeKey`

### Alarms
Consider creating alarms for:
- Excessive decrypt failures
- Unauthorized access attempts
- Grant creation anomalies

## Troubleshooting

### Common Issues

**Issue**: EKS can't decrypt secrets
- Verify key policy includes EKS service
- Check IAM role has KMS permissions
- Ensure key is in enabled state

**Issue**: Node can't mount encrypted volumes
- Verify EC2 service in key policy
- Check node IAM role has decrypt permissions
- Confirm key is in same region

**Issue**: Terraform destroy fails
- Wait for deletion window to expire
- Use `terraform state rm` if stuck
- Check for dependent resources

## Version Requirements

- Terraform >= 1.9
- AWS Provider >= 5.23

## Additional Resources

- [AWS KMS Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html)
- [EKS Encryption](https://docs.aws.amazon.com/eks/latest/userguide/encryption.html)
- [Key Policies](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html)

## Author

Generated for MCK Infrastructure Project

## License

Internal use only

