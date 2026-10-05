# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# An outbound endpoint with fixed addresses and DNS over HTTPS, and a forwarding rule
# that sends the queries for one domain from the VPC to the DNS servers on your network.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC to create the endpoint in"
  type        = string
}

variable "addresses" {
  description = "Two or more IPv4 addresses for the endpoint, each in a subnet of the VPC, keyed by subnet ID; one subnet per Availability Zone"
  type        = map(string)
}

variable "domain_name" {
  description = "The domain whose queries are forwarded, such as corp.example.com"
  type        = string
}

variable "dns_servers" {
  description = "IPv4 addresses of the DNS servers on your network that answer for domain_name"
  type        = list(string)
}

module "resolver_outbound" {
  source = "../../"

  details = {
    scope            = "Example"
    purpose          = "Hybrid DNS"
    environment      = "Development"
    environment_abbr = "dev"
    additional_tags  = { CostCenter = "1234" }
  }

  direction    = "OUTBOUND"
  vpc_id       = var.vpc_id
  ip_addresses = { for subnet_id, ip in var.addresses : subnet_id => { subnet_id = subnet_id, ip = ip } }

  # Plain DNS and DNS over HTTPS: the endpoint may reach the DNS servers on UDP and
  # TCP port 53 and on TCP port 443, and nothing else.
  protocols = ["Do53", "DoH"]
  security_group_rules = {
    for ip in var.dns_servers : replace(ip, ".", "_") => { cidr_ipv4 = "${ip}/32", description = "DNS server ${ip}" }
  }
}

# Forward the queries for domain_name through the endpoint to the DNS servers.
resource "aws_route53_resolver_rule" "forward" {
  name                 = "${module.resolver_outbound.metadata.route53_resolver_endpoint.name}-${replace(var.domain_name, ".", "_")}"
  domain_name          = var.domain_name
  rule_type            = "FORWARD"
  resolver_endpoint_id = module.resolver_outbound.metadata.route53_resolver_endpoint.id

  dynamic "target_ip" {
    for_each = var.dns_servers
    content {
      ip       = target_ip.value
      port     = 53
      protocol = "Do53"
    }
  }

  tags = module.resolver_outbound.metadata.details.tags
}

# Apply the rule to the VPC.
resource "aws_route53_resolver_rule_association" "forward" {
  resolver_rule_id = aws_route53_resolver_rule.forward.id
  vpc_id           = var.vpc_id
}

output "endpoint_id" {
  description = "ID of the outbound endpoint, for more forwarding rules"
  value       = module.resolver_outbound.metadata.route53_resolver_endpoint.id
}

output "rule_id" {
  description = "ID of the forwarding rule, to share with other accounts or associate with other VPCs"
  value       = aws_route53_resolver_rule.forward.id
}
