variable "region" {
  description = "AWS region (used by root provider; kept here for convenience)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "ID of the VPC where EKS will run"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS and node groups"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for EKS secrets encryption. If provided, enables encryption at rest for Kubernetes secrets."
  type        = string
  default     = ""
}

########################
# IAM ROLE VARS        #
########################

variable "create_iam_roles" {
  description = "Whether to create IAM roles for cluster and nodes. Set to false when using external IAM roles."
  type        = bool
  default     = true
}

variable "cluster_role_arn" {
  description = "ARN of existing IAM role for the EKS cluster. Required when create_iam_roles is false."
  type        = string
  default     = ""

  validation {
    condition = (
      var.cluster_role_arn == "" 
      || can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.+", var.cluster_role_arn))
    )
    error_message = "The cluster_role_arn must be a valid IAM role ARN (e.g., arn:aws:iam::123456789012:role/role-name) or empty string."
  }
}

variable "node_role_arn" {
  description = "ARN of existing IAM role for the EKS nodes. Required when create_iam_roles is false."
  type        = string
  default     = ""

  validation {
    condition = (
      var.node_role_arn == "" 
      || can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/.+", var.node_role_arn))
    )
    error_message = "The node_role_arn must be a valid IAM role ARN (e.g., arn:aws:iam::123456789012:role/role-name) or empty string."
  }
}

variable "enable_public_access" {
  description = "Whether the EKS API is accessible publicly"
  type        = bool
  default     = true
}

variable "enable_private_access" {
  description = "Whether the EKS API is accessible within the VPC"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

########################
# SECURITY GROUP VARS  #
########################

variable "create_cluster_security_group" {
  description = "Whether to create a security group for the EKS cluster. If false, cluster_security_group_id must be provided."
  type        = bool
  default     = true
}

variable "cluster_security_group_id" {
  description = "Existing security group ID to attach to the EKS cluster when create_cluster_security_group is false."
  type        = string
  default     = ""

  validation {
    condition = (
      var.create_cluster_security_group == true
      || (var.create_cluster_security_group == false && var.cluster_security_group_id != "")
    )
    error_message = "When create_cluster_security_group is false, you must provide a non-empty cluster_security_group_id."
  }
}

variable "cluster_security_group_ingress_rules" {
  description = <<EOT
List of ingress rules for the cluster security group (only used when create_cluster_security_group = true).
Each object:
  - description
  - from_port
  - to_port
  - protocol
  - cidr_blocks (list of CIDRs)
NOTE: For security, avoid using 0.0.0.0/0. Use VPC CIDR or specific IPs.
EOT
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = []

  validation {
    condition = alltrue([
      for rule in var.cluster_security_group_ingress_rules :
      !(rule.from_port == 0 && rule.to_port == 0 && rule.protocol == "-1" && contains(rule.cidr_blocks, "0.0.0.0/0"))
    ])
    error_message = "All traffic ingress from 0.0.0.0/0 is not allowed. Specify specific ports and protocols."
  }

  validation {
    condition = alltrue([
      for rule in var.cluster_security_group_ingress_rules :
      !(rule.from_port == 22 && contains(rule.cidr_blocks, "0.0.0.0/0"))
    ])
    error_message = "SSH (port 22) should not be open to 0.0.0.0/0. Restrict to specific CIDR blocks."
  }
}

variable "cluster_security_group_additional_rules" {
  description = "Additional security group rules for the cluster (supports security_groups for SG-to-SG rules)"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
    self            = optional(bool, false)
  }))
  default = []
}

variable "cluster_security_group_egress_rules" {
  description = "Egress rules for the cluster security group (more granular than egress_cidrs)"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "HTTPS outbound for AWS APIs"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "allow_all_cluster_egress" {
  description = "Allow all egress from cluster security group (less secure, use only if needed)"
  type        = bool
  default     = false
}

########################
# NODE GROUP VARS      #
########################

variable "node_group_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 3
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 6
}

variable "node_group_instance_types" {
  description = "Instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_capacity_type" {
  description = "Capacity type: ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

variable "node_group_labels" {
  description = "Kubernetes labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "node_group_tags" {
  description = "Extra tags on the node group resources"
  type        = map(string)
  default     = {}
}

########################
# COMMON TAGS / OIDC   #
########################

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "oidc_thumbprint" {
  description = "Thumbprint for the EKS OIDC provider (default for public EKS OIDC)"
  type        = string
  default     = "9e99a48a9960b14926bb7f3b02e22da0afd10df6"
}
