# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Regression tests for the bugs fixed when the module was rewritten as 1.0.0.
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

# The security group description contained the literal text "{local.direction.name}".
run "description_names_the_direction" {
  command = plan
  variables { direction = "OUTBOUND" }
  assert {
    condition     = !strcontains(aws_security_group.this.description, "{") && endswith(aws_security_group.this.description, "Outbound endpoint")
    error_message = "The description must name the direction."
  }
}

# An address for a subnet missing from the subnet list was silently dropped. Each
# address now carries its own subnet.
run "address_keeps_its_subnet" {
  command = plan
  variables {
    ip_addresses = {
      a = { subnet_id = "subnet-0000000000000000a" }
      c = { subnet_id = "subnet-0000000000000000c", ip = "10.0.3.10" }
    }
  }
  assert {
    condition     = contains([for a in aws_route53_resolver_endpoint.this.ip_address : "${a.subnet_id}=${a.ip}" if a.subnet_id == "subnet-0000000000000000c"], "subnet-0000000000000000c=10.0.3.10")
    error_message = "The address must be used in its subnet."
  }
}

# Every rule was created in both directions: an OUTBOUND endpoint also accepted
# queries, and an INBOUND endpoint could also send them.
run "inbound_has_no_egress" {
  command = plan
  variables { security_group_rules = { all = { cidr_ipv4 = "10.0.0.0/8" } } }
  assert {
    condition     = length(aws_vpc_security_group_egress_rule.this) == 0 && length(aws_vpc_security_group_ingress_rule.this) == 2
    error_message = "INBOUND must have ingress rules only."
  }
}

# Port 853 (DNS over TLS) was opened, which Route 53 Resolver does not use, and port
# 443 for DNS over HTTPS never was.
run "no_port_853" {
  command = plan
  variables {
    protocols            = ["Do53", "DoH"]
    security_group_rules = { all = { cidr_ipv4 = "10.0.0.0/8" } }
  }
  assert {
    condition     = join(",", sort([for r in values(aws_vpc_security_group_ingress_rule.this) : tostring(r.from_port)])) == "443,53,53"
    error_message = "Only ports 53 and 443 may be opened."
  }
}

# The security group had a fixed name with create_before_destroy, so any change that
# replaced it while keeping the name failed: two groups in a VPC cannot share a name.
run "security_group_uses_a_name_prefix" {
  command = plan
  assert {
    condition     = aws_security_group.this.name_prefix == "test-dns-test-use1-inbound-"
    error_message = "The group must take a generated name from a prefix."
  }
}
