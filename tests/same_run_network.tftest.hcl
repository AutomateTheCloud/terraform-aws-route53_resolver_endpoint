# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Same-run network: a VPC, subnets and a security group created in the same
# configuration as the endpoint, so their IDs are unknown at plan time.
run "same_run_network_plans" {
  command = plan
  module {
    source = "./tests/fixtures/same_run_network"
  }
}

run "same_run_network_applies" {
  command = apply
  module {
    source = "./tests/fixtures/same_run_network"
  }
  assert {
    condition     = length(module.inbound.metadata.vpc_security_group_ingress_rule) == 4 && length(module.inbound.metadata.route53_resolver_endpoint.ip_address) == 2
    error_message = "Expected four rules and two addresses."
  }
}

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_vpc" {
    defaults = { id = "vpc-0123456789abcdef0", cidr_block = "10.0.0.0/16" }
  }
  mock_resource "aws_subnet" {
    defaults = { id = "subnet-0000000000000000a", cidr_block = "10.0.1.0/24" }
  }
}
