# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
    - `route53_resolver_endpoint` - The endpoint, with its `id` (use it as `resolver_endpoint_id` in forwarding rules), `arn`, `name`, `direction`, `host_vpc_id`, `protocols`, `resolver_endpoint_type`, `security_group_ids`, `region`, `tags`, `tags_all`, and `ip_address`: one entry per address, with its `subnet_id`, `ip` and `ip_id`. The `ip` values are the addresses to forward queries to for an `INBOUND` endpoint.
    - `security_group` - The endpoint's security group, with its `id`, `arn`, `name`, `name_prefix`, `description`, `vpc_id`, `owner_id`, `revoke_rules_on_delete`, `region`, `tags` and `tags_all`. Its rules are in the two entries below.
    - `vpc_security_group_ingress_rule` - The ingress rules of an `INBOUND` endpoint, keyed `<entry>-<protocol>-<port>` (such as `on_premises-udp-53`), or `null` when there are none.
    - `vpc_security_group_egress_rule` - The egress rules of an `OUTBOUND` endpoint, keyed the same way, or `null` when there are none.
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    # One entry per resource. Resources that are not created are null.
    route53_resolver_endpoint       = local.output_resources.route53_resolver_endpoint
    security_group                  = local.output_resources.security_group
    vpc_security_group_egress_rule  = local.output_resources.vpc_security_group_egress_rule
    vpc_security_group_ingress_rule = local.output_resources.vpc_security_group_ingress_rule
  }
}

locals {
  # Each resource's attributes are listed one by one. Referencing a whole resource, or
  # iterating over it, would also reference its deprecated attributes, and every
  # caller's plan would print deprecation warnings.
  output_resources = {
    # Left out: rni_enhanced_metrics_enabled and target_name_server_metrics_enabled,
    # which are newer than the provider floor.
    route53_resolver_endpoint = {
      arn                    = aws_route53_resolver_endpoint.this.arn
      direction              = aws_route53_resolver_endpoint.this.direction
      host_vpc_id            = aws_route53_resolver_endpoint.this.host_vpc_id
      id                     = aws_route53_resolver_endpoint.this.id
      ip_address             = aws_route53_resolver_endpoint.this.ip_address
      name                   = aws_route53_resolver_endpoint.this.name
      protocols              = aws_route53_resolver_endpoint.this.protocols
      region                 = aws_route53_resolver_endpoint.this.region
      resolver_endpoint_type = aws_route53_resolver_endpoint.this.resolver_endpoint_type
      security_group_ids     = aws_route53_resolver_endpoint.this.security_group_ids
      tags                   = aws_route53_resolver_endpoint.this.tags
      tags_all               = aws_route53_resolver_endpoint.this.tags_all
    }

    # Left out: ingress and egress, the group's inline rules. They are read when the
    # group is created, before the module's rules are attached, so they would change
    # on every caller's next plan. The rules are in vpc_security_group_*_rule instead.
    security_group = {
      arn                    = aws_security_group.this.arn
      description            = aws_security_group.this.description
      id                     = aws_security_group.this.id
      name                   = aws_security_group.this.name
      name_prefix            = aws_security_group.this.name_prefix
      owner_id               = aws_security_group.this.owner_id
      region                 = aws_security_group.this.region
      revoke_rules_on_delete = aws_security_group.this.revoke_rules_on_delete
      tags                   = aws_security_group.this.tags
      tags_all               = aws_security_group.this.tags_all
      vpc_id                 = aws_security_group.this.vpc_id
    }

    # Keyed "<entry>-<protocol>-<port>", such as "on_premises-udp-53".
    vpc_security_group_egress_rule = length(aws_vpc_security_group_egress_rule.this) == 0 ? null : {
      for k in keys(aws_vpc_security_group_egress_rule.this) : k => {
        arn                          = aws_vpc_security_group_egress_rule.this[k].arn
        cidr_ipv4                    = aws_vpc_security_group_egress_rule.this[k].cidr_ipv4
        cidr_ipv6                    = aws_vpc_security_group_egress_rule.this[k].cidr_ipv6
        description                  = aws_vpc_security_group_egress_rule.this[k].description
        from_port                    = aws_vpc_security_group_egress_rule.this[k].from_port
        id                           = aws_vpc_security_group_egress_rule.this[k].id
        ip_protocol                  = aws_vpc_security_group_egress_rule.this[k].ip_protocol
        prefix_list_id               = aws_vpc_security_group_egress_rule.this[k].prefix_list_id
        referenced_security_group_id = aws_vpc_security_group_egress_rule.this[k].referenced_security_group_id
        region                       = aws_vpc_security_group_egress_rule.this[k].region
        security_group_id            = aws_vpc_security_group_egress_rule.this[k].security_group_id
        security_group_rule_id       = aws_vpc_security_group_egress_rule.this[k].security_group_rule_id
        tags                         = aws_vpc_security_group_egress_rule.this[k].tags
        tags_all                     = aws_vpc_security_group_egress_rule.this[k].tags_all
        to_port                      = aws_vpc_security_group_egress_rule.this[k].to_port
      }
    }

    # Keyed "<entry>-<protocol>-<port>", such as "on_premises-udp-53".
    vpc_security_group_ingress_rule = length(aws_vpc_security_group_ingress_rule.this) == 0 ? null : {
      for k in keys(aws_vpc_security_group_ingress_rule.this) : k => {
        arn                          = aws_vpc_security_group_ingress_rule.this[k].arn
        cidr_ipv4                    = aws_vpc_security_group_ingress_rule.this[k].cidr_ipv4
        cidr_ipv6                    = aws_vpc_security_group_ingress_rule.this[k].cidr_ipv6
        description                  = aws_vpc_security_group_ingress_rule.this[k].description
        from_port                    = aws_vpc_security_group_ingress_rule.this[k].from_port
        id                           = aws_vpc_security_group_ingress_rule.this[k].id
        ip_protocol                  = aws_vpc_security_group_ingress_rule.this[k].ip_protocol
        prefix_list_id               = aws_vpc_security_group_ingress_rule.this[k].prefix_list_id
        referenced_security_group_id = aws_vpc_security_group_ingress_rule.this[k].referenced_security_group_id
        region                       = aws_vpc_security_group_ingress_rule.this[k].region
        security_group_id            = aws_vpc_security_group_ingress_rule.this[k].security_group_id
        security_group_rule_id       = aws_vpc_security_group_ingress_rule.this[k].security_group_rule_id
        tags                         = aws_vpc_security_group_ingress_rule.this[k].tags
        tags_all                     = aws_vpc_security_group_ingress_rule.this[k].tags_all
        to_port                      = aws_vpc_security_group_ingress_rule.this[k].to_port
      }
    }
  }
}
