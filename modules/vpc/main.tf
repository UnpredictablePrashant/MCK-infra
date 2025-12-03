########################################
# VPC
########################################

resource "aws_vpc" "this" {
  count                = var.enable_vpc ? 1 : 0
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-vpc"
    }
  )
}

########################################
# Subnets
########################################

# Public subnets
resource "aws_subnet" "public" {
  count = var.enable_vpc && length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  vpc_id                  = local.vpc_id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-${count.index + 1}"
      Tier = "public"
    }
  )
}

# Private subnets
resource "aws_subnet" "private" {
  count = var.enable_vpc && length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  vpc_id            = local.vpc_id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-${count.index + 1}"
      Tier = "private"
    }
  )
}

########################################
# Internet Gateway
########################################

resource "aws_internet_gateway" "this" {
  count = var.enable_vpc && var.enable_internet_gateway ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

########################################
# NAT Gateway (single)
########################################

# Elastic IP for NAT
resource "aws_eip" "nat" {
  count = var.enable_vpc && var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "this" {
  count = var.enable_vpc && var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  # put NAT in first public subnet
  subnet_id = length(aws_subnet.public) > 0 ? aws_subnet.public[0].id : null

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-gw"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

########################################
# Route Tables
########################################

# Public route table
resource "aws_route_table" "public" {
  count = var.enable_vpc && var.enable_route_tables && length(aws_subnet.public) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-rt"
    }
  )
}

# Route for internet access via IGW
resource "aws_route" "public_internet_access" {
  count = (var.enable_vpc
    && var.enable_route_tables
    && var.enable_internet_gateway
    && length(aws_route_table.public) > 0
    && length(aws_internet_gateway.this) > 0) ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

# Associate public subnets with public RT
resource "aws_route_table_association" "public_association" {
  count = (var.enable_vpc
    && var.enable_route_tables
    && length(aws_route_table.public) > 0
    ? length(aws_subnet.public)
    : 0)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private route table
resource "aws_route_table" "private" {
  count = (var.enable_vpc
    && var.enable_route_tables
    && length(aws_subnet.private) > 0
    ? 1
    : 0)

  vpc_id = local.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-rt"
    }
  )
}

# Route for private subnets -> NAT
resource "aws_route" "private_nat_access" {
  count = (var.enable_vpc
    && var.enable_route_tables
    && var.enable_nat_gateway
    && length(aws_route_table.private) > 0
    && length(aws_nat_gateway.this) > 0
    ? 1
    : 0)

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

# Associate private subnets with private RT
resource "aws_route_table_association" "private_association" {
  count = (var.enable_vpc
    && var.enable_route_tables
    && length(aws_route_table.private) > 0
    ? length(aws_subnet.private)
    : 0)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

########################################
# Security Group
########################################

resource "aws_security_group" "default" {
  count = var.enable_vpc && var.enable_security_group ? 1 : 0

  name_prefix            = "${coalesce(var.security_group_name, var.name)}-sg-"
  description            = var.security_group_description
  vpc_id                 = local.vpc_id
  revoke_rules_on_delete = var.revoke_rules_on_delete

  # Dynamic ingress rules - users define their own rules
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      security_groups  = ingress.value.security_groups
      self             = ingress.value.self
    }
  }

  # Dynamic egress rules - controlled outbound access
  dynamic "egress" {
    for_each = var.allow_all_egress ? [] : var.egress_rules
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      security_groups  = egress.value.security_groups
      self             = egress.value.self
    }
  }

  # Optional: Allow all egress (only if explicitly enabled)
  dynamic "egress" {
    for_each = var.allow_all_egress ? [1] : []
    content {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${coalesce(var.security_group_name, var.name)}-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
