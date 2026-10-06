# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  direction = {
    name = var.direction == "INBOUND" ? "Inbound" : "Outbound"
    abbr = lower(var.direction)
  }

  # The name of the endpoint, and the Name tag of the endpoint and its security group.
  name = "${local.scope.abbr}-${local.purpose.abbr}-${local.environment.abbr}-${local.aws.region.abbr}-${local.direction.abbr}"

  # The ports each protocol needs.
  protocol_ports = {
    Do53       = [{ ip_protocol = "udp", port = 53 }, { ip_protocol = "tcp", port = 53 }]
    DoH        = [{ ip_protocol = "tcp", port = 443 }]
    "DoH-FIPS" = [{ ip_protocol = "tcp", port = 443 }]
  }
  ports = distinct(flatten([for p in sort(tolist(var.protocols)) : local.protocol_ports[p]]))

  # One rule per entry of security_group_rules and port, keyed "<entry>-<protocol>-<port>".
  # The keys come from the inputs alone, so the rules plan even when a source is created
  # in the same run.
  security_group_rules = merge([
    for key, rule in var.security_group_rules : {
      for p in local.ports : "${key}-${p.ip_protocol}-${p.port}" => merge(rule, p, {
        description = "${coalesce(rule.description, key)} (DNS, ${upper(p.ip_protocol)} ${p.port})"
      })
    }
  ]...)
}
