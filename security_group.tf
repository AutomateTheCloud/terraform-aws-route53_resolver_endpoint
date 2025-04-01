resource "aws_security_group" "this" {
  name                   = "${local.scope.abbr}-${local.purpose.abbr}-${local.environment.abbr}-${local.aws.region.abbr}-r53_rsvl_${local.direction.abbr}"
  description            = "${local.scope.name} - ${local.purpose.name} [${local.environment.name}] (${local.aws.region.name}): Route53 Resolver - {local.direction.name}"
  vpc_id                 = data.aws_vpc.this.id
  revoke_rules_on_delete = true
  tags = merge(
    local.tags,
    tomap({
      "Name" = "${local.scope.abbr}-${local.purpose.abbr}-${local.environment.abbr}-${local.aws.region.abbr}-r53_rsvl_${local.direction.abbr}"
    })
  )
  lifecycle {
    create_before_destroy = true
  }
  provider = aws.this
}
