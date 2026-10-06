# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
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

run "defaults_are_closed" {
  command = apply

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 0 && length(aws_vpc_security_group_egress_rule.this) == 0
    error_message = "No network access may be allowed by default."
  }
  assert {
    condition     = aws_route53_resolver_endpoint.this.protocols == toset(["Do53"]) && aws_route53_resolver_endpoint.this.resolver_endpoint_type == "IPV4"
    error_message = "Plain DNS over IPv4 expected by default."
  }
  assert {
    condition     = aws_route53_resolver_endpoint.this.direction == "INBOUND" && aws_route53_resolver_endpoint.this.name == "test-dns-test-use1-inbound"
    error_message = "Unexpected direction or name."
  }
  assert {
    condition     = aws_route53_resolver_endpoint.this.security_group_ids == toset([aws_security_group.this.id])
    error_message = "The endpoint must use the module's security group."
  }
  assert {
    condition     = toset([for a in aws_route53_resolver_endpoint.this.ip_address : a.subnet_id]) == toset(["subnet-0000000000000000a", "subnet-0000000000000000b"])
    error_message = "One address per entry expected."
  }
  assert {
    condition     = aws_route53_resolver_endpoint.this.tags == tomap({ Scope = "Test", Purpose = "DNS", Environment = "test", Name = "test-dns-test-use1-inbound" })
    error_message = "Unexpected tags."
  }
  assert {
    condition     = startswith(aws_security_group.this.name_prefix, "test-dns-test-use1-inbound-") && aws_security_group.this.vpc_id == "vpc-0123456789abcdef0" && aws_security_group.this.revoke_rules_on_delete
    error_message = "Unexpected security group."
  }
  assert {
    condition     = aws_security_group.this.description == "Test - DNS [test] (us-east-1): Route 53 Resolver Inbound endpoint"
    error_message = "Unexpected security group description."
  }
  assert {
    condition     = output.metadata.vpc_security_group_ingress_rule == null && output.metadata.vpc_security_group_egress_rule == null && output.metadata.aws.region.abbr == "use1" && output.metadata.route53_resolver_endpoint.name == "test-dns-test-use1-inbound" && output.metadata.security_group.id == aws_security_group.this.id
    error_message = "Unexpected metadata output."
  }
}

run "abbreviation_override" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "Name Server", environment = "Production", environment_abbr = "prd", additional_tags = { CostCenter = "1234" } }
  }
  assert {
    condition     = output.metadata.details.environment.abbr == "prd" && output.metadata.details.purpose.machine == "nameserver" && aws_route53_resolver_endpoint.this.name == "test-name_server-prd-use1-inbound" && aws_route53_resolver_endpoint.this.tags["CostCenter"] == "1234"
    error_message = "Unexpected details handling."
  }
}

run "details_scope_required" {
  command = plan
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "details_purpose_required" {
  command = plan
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}

run "details_environment_required" {
  command = plan
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}

run "direction_validated" {
  command = plan
  variables { direction = "inbound" }
  expect_failures = [var.direction]
}

run "inbound_delegation_rejected" {
  command = plan
  variables { direction = "INBOUND_DELEGATION" }
  expect_failures = [var.direction]
}

run "vpc_id_validated" {
  command = plan
  variables { vpc_id = "subnet-0123456789abcdef0" }
  expect_failures = [var.vpc_id]
}

run "two_addresses_required" {
  command = plan
  variables { ip_addresses = { a = { subnet_id = "subnet-0000000000000000a" } } }
  expect_failures = [var.ip_addresses]
}

run "at_most_ten_addresses" {
  command = plan
  variables { ip_addresses = { for i in range(11) : "n${i}" => { subnet_id = "subnet-0000000000000000a" } } }
  expect_failures = [var.ip_addresses]
}

run "address_subnet_validated" {
  command = plan
  variables {
    ip_addresses = {
      a = { subnet_id = "vpc-0123456789abcdef0" }
      b = { subnet_id = "subnet-0000000000000000b" }
    }
  }
  expect_failures = [var.ip_addresses]
}

run "address_must_be_ipv4" {
  command = plan
  variables {
    ip_addresses = {
      a = { subnet_id = "subnet-0000000000000000a", ip = "2001:db8::10" }
      b = { subnet_id = "subnet-0000000000000000b" }
    }
  }
  expect_failures = [var.ip_addresses]
}

run "address_must_be_an_address" {
  command = plan
  variables {
    ip_addresses = {
      a = { subnet_id = "subnet-0000000000000000a", ip = "10.0.1.300" }
      b = { subnet_id = "subnet-0000000000000000b" }
    }
  }
  expect_failures = [var.ip_addresses]
}

run "address_used_once" {
  command = plan
  variables {
    ip_addresses = {
      a = { subnet_id = "subnet-0000000000000000a", ip = "10.0.1.10" }
      b = { subnet_id = "subnet-0000000000000000a", ip = "10.0.1.10" }
    }
  }
  expect_failures = [var.ip_addresses]
}

run "protocols_validated" {
  command = plan
  variables { protocols = ["DoT"] }
  expect_failures = [var.protocols]
}

run "protocols_not_empty" {
  command = plan
  variables { protocols = [] }
  expect_failures = [var.protocols]
}

run "doh_fips_inbound_only" {
  command = plan
  variables {
    direction = "OUTBOUND"
    protocols = ["DoH-FIPS"]
  }
  expect_failures = [var.protocols]
}

run "rule_needs_exactly_one_target" {
  command = plan
  variables { security_group_rules = { both = { cidr_ipv4 = "10.0.0.0/16", security_group_id = "sg-0123456789abcdef0" } } }
  expect_failures = [var.security_group_rules]
}

run "rule_needs_a_target" {
  command = plan
  variables { security_group_rules = { none = { description = "nothing" } } }
  expect_failures = [var.security_group_rules]
}

run "rule_ipv4_validated" {
  command = plan
  variables { security_group_rules = { v6 = { cidr_ipv4 = "2001:db8::/56" } } }
  expect_failures = [var.security_group_rules]
}

run "name_length_checked" {
  command = plan
  variables { details = { scope = "A Very Long Organization Name", purpose = "Resolver For Every Account", environment = "Production" } }
  expect_failures = [aws_route53_resolver_endpoint.this]
}
