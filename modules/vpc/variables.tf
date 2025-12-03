variable "name" {
  description = "Name prefix for VPC and related resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of AZs to use"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDRs (should match azs length if enabled)"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "List of private subnet CIDRs (should match azs length if enabled)"
  type        = list(string)
  default     = []
}

# Toggles
variable "enable_vpc" {
  description = "Create VPC and all dependent resources"
  type        = bool
  default     = true
}

variable "enable_internet_gateway" {
  description = "Create Internet Gateway and attach to VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Create a single NAT Gateway in the first public subnet"
  type        = bool
  default     = false
}

variable "enable_route_tables" {
  description = "Create public and private route tables"
  type        = bool
  default     = true
}

variable "enable_security_group" {
  description = "Create a default security group with basic rules"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name for the security group (uses var.name if not specified)"
  type        = string
  default     = ""
}

variable "security_group_description" {
  description = "Description for the security group"
  type        = string
  default     = "Managed by Terraform"
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups  = optional(list(string), [])
    self             = optional(bool, false)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      !(rule.from_port == 22 && contains(rule.cidr_blocks, "0.0.0.0/0"))
    ])
    error_message = "SSH (port 22) should not be open to 0.0.0.0/0. Restrict to specific CIDR blocks."
  }

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      !(rule.from_port == 3389 && contains(rule.cidr_blocks, "0.0.0.0/0"))
    ])
    error_message = "RDP (port 3389) should not be open to 0.0.0.0/0. Restrict to specific CIDR blocks."
  }

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      !(rule.from_port == 0 && rule.to_port == 0 && rule.protocol == "-1" && contains(rule.cidr_blocks, "0.0.0.0/0"))
    ])
    error_message = "All traffic ingress from 0.0.0.0/0 is not allowed. Specify specific ports and protocols."
  }
}

variable "egress_rules" {
  description = "List of egress rules for the security group"
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups  = optional(list(string), [])
    self             = optional(bool, false)
  }))
  default = [
    {
      description = "Allow HTTPS outbound"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTP outbound"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow DNS outbound"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "allow_all_egress" {
  description = "Allow all outbound traffic (overrides egress_rules if true)"
  type        = bool
  default     = false
}

variable "revoke_rules_on_delete" {
  description = "Revoke all security group rules before deleting the group"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
