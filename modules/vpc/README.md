## VPC Module

A Terraform module to create a VPC with configurable subnets, gateways, route tables, and security groups.

### Security Group Configuration

The security group is designed with security best practices in mind:

#### Built-in Security Validations
- **SSH (port 22)** cannot be opened to `0.0.0.0/0` - must specify restricted CIDR blocks
- **RDP (port 3389)** cannot be opened to `0.0.0.0/0` - must specify restricted CIDR blocks
- **All traffic** ingress from `0.0.0.0/0` is blocked - must specify specific ports/protocols

#### Ingress Rules
Define custom ingress rules using the `ingress_rules` variable:

```hcl
ingress_rules = [
  {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description = "SSH from corporate network only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Restrict to internal networks
  },
  {
    description = "Allow traffic from another security group"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = ["sg-xxxxxxxxx"]
  },
  {
    description = "Allow internal VPC traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true  # Allow traffic from instances in same SG
  }
]
```

#### Egress Rules
By default, egress is restricted to HTTPS (443), HTTP (80), and DNS (53). You can customize:

```hcl
# Option 1: Define specific egress rules
egress_rules = [
  {
    description = "Allow HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
]

# Option 2: Allow all outbound traffic (less secure)
allow_all_egress = true
```

#### Rule Object Schema

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `description` | string | Yes | Description of the rule |
| `from_port` | number | Yes | Start port |
| `to_port` | number | Yes | End port |
| `protocol` | string | Yes | Protocol (tcp, udp, icmp, -1 for all) |
| `cidr_blocks` | list(string) | No | IPv4 CIDR blocks |
| `ipv6_cidr_blocks` | list(string) | No | IPv6 CIDR blocks |
| `security_groups` | list(string) | No | Source security group IDs |
| `self` | bool | No | Allow traffic from same security group |

### Usage Example

```hcl
module "vpc" {
  source = "./modules/vpc"

  name            = "production"
  cidr_block      = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.2.0/24", "10.0.3.0/24"]

  enable_vpc              = true
  enable_internet_gateway = true
  enable_nat_gateway      = true
  enable_route_tables     = true
  enable_security_group   = true

  ingress_rules = [
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  allow_all_egress = false

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```