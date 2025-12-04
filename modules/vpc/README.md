# VPC Module

Terraform module for creating AWS VPC with public/private subnets, NAT Gateway, Internet Gateway, and optional security groups.

## Features

- ✅ VPC with configurable CIDR block
- ✅ Public and private subnets across multiple AZs
- ✅ Internet Gateway for public subnet internet access
- ✅ NAT Gateway for private subnet internet access (optional)
- ✅ Route tables with automatic associations
- ✅ Security groups with customizable rules
- ✅ Built-in security validations

## Usage

### Basic Configuration

```hcl
module "vpc" {
  source = "./modules/vpc"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_vpc              = true
  enable_internet_gateway = true
  enable_nat_gateway      = true
  enable_route_tables     = true
  enable_security_group   = false

  tags = {
    Environment = "production"
  }
}
```

### With Custom Security Group Rules

```hcl
module "vpc" {
  source = "./modules/vpc"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_security_group = true

  ingress_rules = [
    {
      description = "HTTPS from anywhere"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "SSH from corporate network"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]

  # Use default egress (HTTPS, HTTP, DNS) or allow all
  allow_all_egress = false
}
```

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `name` | string | Name prefix for VPC and related resources |
| `azs` | list(string) | List of availability zones to use |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cidr_block` | string | `"10.0.0.0/16"` | CIDR block for the VPC |
| `public_subnets` | list(string) | `[]` | List of public subnet CIDRs |
| `private_subnets` | list(string) | `[]` | List of private subnet CIDRs |
| `enable_vpc` | bool | `true` | Create VPC and dependent resources |
| `enable_internet_gateway` | bool | `true` | Create Internet Gateway |
| `enable_nat_gateway` | bool | `false` | Create NAT Gateway |
| `enable_route_tables` | bool | `true` | Create route tables |
| `enable_security_group` | bool | `true` | Create security group |

### Security Group Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ingress_rules` | list(object) | `[]` | List of ingress rules |
| `egress_rules` | list(object) | See defaults | List of egress rules |
| `allow_all_egress` | bool | `false` | Allow all outbound traffic |
| `revoke_rules_on_delete` | bool | `true` | Revoke rules before deletion |

### Ingress/Egress Rule Object

```hcl
{
  description      = string
  from_port        = number
  to_port          = number
  protocol         = string
  cidr_blocks      = list(string)
  ipv6_cidr_blocks = optional(list(string))
  security_groups  = optional(list(string))
  self             = optional(bool)
}
```

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `internet_gateway_id` | Internet Gateway ID |
| `nat_gateway_id` | NAT Gateway ID |
| `public_route_table_id` | Public route table ID |
| `private_route_table_id` | Private route table ID |
| `security_group_id` | Security group ID |
| `security_group_arn` | Security group ARN |
| `security_group_name` | Security group name |

## Security Features

### Built-in Validations

The module includes security validations to prevent common misconfigurations:

- ❌ **SSH (port 22)** cannot be opened to `0.0.0.0/0`
- ❌ **RDP (port 3389)** cannot be opened to `0.0.0.0/0`
- ❌ **All traffic** ingress from `0.0.0.0/0` is blocked

### Default Egress Rules

By default, egress is restricted to:
- HTTPS (443)
- HTTP (80)
- DNS (53)

Set `allow_all_egress = true` to allow all outbound traffic.

## Examples

### Minimal VPC (No NAT Gateway)

```hcl
module "vpc" {
  source = "./modules/vpc"

  name       = "dev-vpc"
  cidr_block = "10.0.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway    = false  # No NAT for cost savings
  enable_security_group = false
}
```

### Production VPC with NAT

```hcl
module "vpc" {
  source = "./modules/vpc"

  name       = "prod-vpc"
  cidr_block = "10.0.0.0/16"
  azs        = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true  # Enable NAT for private subnet internet access

  tags = {
    Environment = "production"
    Critical    = "true"
  }
}
```

## Network Architecture

```
┌─────────────────────────────────────────────┐
│              VPC (10.0.0.0/16)              │
├─────────────────────┬───────────────────────┤
│  Public Subnets     │  Private Subnets      │
│  - 10.0.0.0/24      │  - 10.0.10.0/24       │
│  - 10.0.1.0/24      │  - 10.0.11.0/24       │
│                     │                       │
│  ┌────────────┐     │  ┌────────────┐       │
│  │    IGW     │     │  │    NAT     │       │
│  └──────┬─────┘     │  └──────┬─────┘       │
│         │           │         │             │
│  ┌──────▼─────┐     │  ┌──────▼─────┐       │
│  │ Public RT  │     │  │ Private RT │       │
│  └────────────┘     │  └────────────┘       │
└─────────────────────┴───────────────────────┘
         │                     │
         ▼                     ▼
     Internet            AWS Services
```

## Cost Considerations

| Resource | Cost (us-east-1) |
|----------|------------------|
| VPC | Free |
| Subnets | Free |
| Internet Gateway | Free |
| NAT Gateway | ~$32/month + data transfer |
| Route Tables | Free |

**Note**: NAT Gateway is the most expensive component. Consider disabling for dev/test environments.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | ~> 5.0 |
