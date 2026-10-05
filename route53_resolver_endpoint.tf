# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_route53_resolver_endpoint" "this" {
  region                 = var.region
  name                   = local.name
  direction              = var.direction
  resolver_endpoint_type = "IPV4"
  protocols              = var.protocols
  security_group_ids     = [aws_security_group.this.id]

  dynamic "ip_address" {
    for_each = var.ip_addresses
    content {
      subnet_id = ip_address.value.subnet_id
      ip        = ip_address.value.ip
    }
  }

  tags = merge(local.tags, { Name = local.name })

  lifecycle {
    precondition {
      condition     = length(local.name) <= 64
      error_message = "The endpoint name \"${local.name}\" is longer than the 64 characters AWS allows. Shorten it with details.scope_abbr, details.purpose_abbr or details.environment_abbr."
    }
  }
}
