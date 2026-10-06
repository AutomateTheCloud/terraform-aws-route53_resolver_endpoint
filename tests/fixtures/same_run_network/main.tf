# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Test fixture: the network is created in the same run as the endpoint, so the VPC,
# subnet and security group IDs are not known until apply.
terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "a" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "b" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_security_group" "dns_servers" {
  name        = "dns-servers"
  description = "DNS servers that forward to the endpoint"
  vpc_id      = aws_vpc.this.id
}

module "inbound" {
  source = "../../.."

  details   = { scope = "Test", purpose = "Same Run", environment = "test" }
  direction = "INBOUND"
  vpc_id    = aws_vpc.this.id
  ip_addresses = {
    a = { subnet_id = aws_subnet.a.id, ip = cidrhost(aws_subnet.a.cidr_block, 53) }
    b = { subnet_id = aws_subnet.b.id }
  }
  security_group_rules = {
    vpc         = { cidr_ipv4 = aws_vpc.this.cidr_block }
    dns_servers = { security_group_id = aws_security_group.dns_servers.id }
  }
}
