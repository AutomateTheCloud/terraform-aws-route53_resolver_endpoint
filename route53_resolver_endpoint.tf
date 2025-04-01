resource "aws_route53_resolver_endpoint" "this" {
  name               = "${local.scope.abbr}-${local.purpose.abbr}-${local.environment.abbr}-${local.aws.region.abbr}-${local.direction.abbr}"
  direction          = upper(var.direction)
  security_group_ids = [aws_security_group.this.id]
  dynamic "ip_address" {
    for_each = local.subnet.ids
    content {
      ip        = lookup(var.ip_address_assignment, ip_address.value, null)
      subnet_id = ip_address.value
    }
  }
  tags = merge(
    local.tags,
    tomap({
      "Name" = "${local.scope.abbr}-${local.purpose.abbr}-${local.environment.abbr}-${local.aws.region.abbr}-${local.direction.abbr}"
    })
  )
  provider = aws.this
}
