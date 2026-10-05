# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# An inbound endpoint that the DNS servers on your network can forward queries to, so
# they can resolve names in the VPC, such as records in its private hosted zones.

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

variable "subnet_ids" {
  description = "IDs of two or more subnets of the VPC, each in a different Availability Zone"
  type        = list(string)
}

variable "dns_server_cidr" {
  description = "IPv4 range of the DNS servers on your network that will forward queries to the endpoint"
  type        = string
}

module "resolver_inbound" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Hybrid DNS"
    environment = "Development"
  }

  direction    = "INBOUND"
  vpc_id       = var.vpc_id
  ip_addresses = { for id in var.subnet_ids : id => { subnet_id = id } }

  security_group_rules = {
    dns_servers = { cidr_ipv4 = var.dns_server_cidr, description = "DNS servers on your network" }
  }
}

output "ip_addresses" {
  description = "The addresses to forward queries to"
  value       = [for a in module.resolver_inbound.metadata.route53_resolver_endpoint.ip_address : a.ip]
}
