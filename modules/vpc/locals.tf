locals {
  vpc_id = var.enable_vpc ? aws_vpc.this[0].id : null
}