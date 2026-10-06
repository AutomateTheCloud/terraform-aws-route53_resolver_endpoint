# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# An OUTBOUND endpoint sends queries: one egress rule per destination and port.
resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = var.direction == "OUTBOUND" ? local.security_group_rules : {}

  region            = var.region
  security_group_id = aws_security_group.this.id
  description       = each.value.description
  ip_protocol       = each.value.ip_protocol
  from_port         = each.value.port
  to_port           = each.value.port

  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.security_group_id
  prefix_list_id               = each.value.prefix_list_id

  tags = merge(local.tags, { Name = "${local.name}-${each.key}" })
}
