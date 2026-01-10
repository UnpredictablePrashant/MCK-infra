locals {
  vpc_id = var.enable_vpc ? aws_vpc.this[0].id : null
  
  # Merge mandatory tags with user-provided tags
  common_tags = merge(
    var.tags,
    {
      product_id = var.product_id
      used_for   = var.used_for
    }
  )
}