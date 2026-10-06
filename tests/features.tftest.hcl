# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  details   = { scope = "Test", purpose = "DNS", environment = "test" }
  direction = "INBOUND"
  vpc_id    = "vpc-0123456789abcdef0"
  ip_addresses = {
    a = { subnet_id = "subnet-0000000000000000a" }
    b = { subnet_id = "subnet-0000000000000000b" }
  }
}

run "inbound_rules_every_target_type" {
  command = plan
  variables {
    security_group_rules = {
      on_premises = { cidr_ipv4 = "192.168.0.0/16", description = "Data center DNS servers" }
      peered      = { security_group_id = "sg-0123456789abcdef0" }
      offices     = { prefix_list_id = "pl-0123456789abcdef0" }
    }
  }
  assert {
    condition     = toset(keys(aws_vpc_security_group_ingress_rule.this)) == toset(["on_premises-udp-53", "on_premises-tcp-53", "peered-udp-53", "peered-tcp-53", "offices-udp-53", "offices-tcp-53"]) && length(aws_vpc_security_group_egress_rule.this) == 0
    error_message = "INBOUND needs ingress rules for UDP and TCP 53 per entry, and no egress rules."
  }
  assert {
    condition = alltrue([
      aws_vpc_security_group_ingress_rule.this["on_premises-udp-53"].cidr_ipv4 == "192.168.0.0/16",
      aws_vpc_security_group_ingress_rule.this["on_premises-udp-53"].ip_protocol == "udp",
      aws_vpc_security_group_ingress_rule.this["on_premises-tcp-53"].ip_protocol == "tcp",
      aws_vpc_security_group_ingress_rule.this["on_premises-udp-53"].description == "Data center DNS servers (DNS, UDP 53)",
      aws_vpc_security_group_ingress_rule.this["peered-tcp-53"].referenced_security_group_id == "sg-0123456789abcdef0",
      aws_vpc_security_group_ingress_rule.this["peered-tcp-53"].description == "peered (DNS, TCP 53)",
      aws_vpc_security_group_ingress_rule.this["offices-udp-53"].prefix_list_id == "pl-0123456789abcdef0",
    ])
    error_message = "Each target must reach its own attribute."
  }
  assert {
    condition     = alltrue([for r in values(aws_vpc_security_group_ingress_rule.this) : r.from_port == 53 && r.to_port == 53])
    error_message = "Rules must allow port 53 only."
  }
}

run "outbound_rules_are_egress" {
  command = apply
  variables {
    direction            = "OUTBOUND"
    security_group_rules = { on_premises = { cidr_ipv4 = "192.168.10.0/24" } }
  }
  assert {
    condition     = toset(keys(aws_vpc_security_group_egress_rule.this)) == toset(["on_premises-udp-53", "on_premises-tcp-53"]) && length(aws_vpc_security_group_ingress_rule.this) == 0
    error_message = "OUTBOUND needs egress rules for UDP and TCP 53, and no ingress rules."
  }
  assert {
    condition     = aws_route53_resolver_endpoint.this.direction == "OUTBOUND" && aws_route53_resolver_endpoint.this.name == "test-dns-test-use1-outbound" && endswith(aws_security_group.this.description, "Route 53 Resolver Outbound endpoint")
    error_message = "Unexpected direction or name."
  }
  assert {
    condition     = output.metadata.vpc_security_group_ingress_rule == null && output.metadata.vpc_security_group_egress_rule["on_premises-tcp-53"].cidr_ipv4 == "192.168.10.0/24"
    error_message = "Unexpected metadata output."
  }
}

run "doh_opens_443_only" {
  command = plan
  variables {
    protocols            = ["DoH"]
    security_group_rules = { on_premises = { cidr_ipv4 = "192.168.0.0/16" } }
  }
  assert {
    condition     = keys(aws_vpc_security_group_ingress_rule.this) == ["on_premises-tcp-443"] && aws_vpc_security_group_ingress_rule.this["on_premises-tcp-443"].from_port == 443
    error_message = "DoH needs TCP 443 only."
  }
  assert {
    condition     = aws_route53_resolver_endpoint.this.protocols == toset(["DoH"])
    error_message = "The protocol must reach the endpoint."
  }
}

run "do53_and_doh_fips" {
  command = plan
  variables {
    protocols            = ["Do53", "DoH-FIPS"]
    security_group_rules = { on_premises = { cidr_ipv4 = "192.168.0.0/16" } }
  }
  assert {
    condition     = toset(keys(aws_vpc_security_group_ingress_rule.this)) == toset(["on_premises-udp-53", "on_premises-tcp-53", "on_premises-tcp-443"])
    error_message = "Do53 and DoH-FIPS need UDP 53, TCP 53 and TCP 443."
  }
}

run "fixed_addresses" {
  command = plan
  variables {
    ip_addresses = {
      a = { subnet_id = "subnet-0000000000000000a", ip = "10.0.1.53" }
      b = { subnet_id = "subnet-0000000000000000b", ip = "10.0.2.53" }
      c = { subnet_id = "subnet-0000000000000000b", ip = "10.0.2.54" }
    }
  }
  assert {
    condition     = toset([for a in aws_route53_resolver_endpoint.this.ip_address : "${a.subnet_id}=${a.ip}"]) == toset(["subnet-0000000000000000a=10.0.1.53", "subnet-0000000000000000b=10.0.2.53", "subnet-0000000000000000b=10.0.2.54"])
    error_message = "Each address must reach its subnet, including two in one subnet."
  }
}
