# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "direction" {
  description = <<-EOT
    Which way DNS queries go through the endpoint:

    - `INBOUND` - Your network, or another VPC, sends queries to the endpoint, and Route 53 Resolver answers them from this VPC's view of DNS (private hosted zones, VPC names).
    - `OUTBOUND` - Route 53 Resolver forwards queries from this VPC to DNS servers elsewhere, such as on your network. Forwarding rules (`aws_route53_resolver_rule`) decide which domains are forwarded; the endpoint only provides the network path.

    Changing the direction replaces the endpoint.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = contains(["INBOUND", "OUTBOUND"], var.direction)
    error_message = "direction must be INBOUND or OUTBOUND."
  }
}

variable "ip_addresses" {
  description = <<-EOT
    The network interfaces of the endpoint: one entry per IP address, each in a subnet of `vpc_id`. AWS requires at least 2. The AWS provider accepts at most 10, and an account quota allows 6 by default. Put them in subnets in different Availability Zones, so the endpoint keeps working when one zone fails. The keys are names you choose, such as the Availability Zone (`a`, `b`); they only identify each address, so a subnet created in the same configuration can be used.

    Each entry takes:

    - `subnet_id` - (Required) The subnet to create the address in.
    - `ip` - (Optional) The IPv4 address to use, from the subnet's range. Without it, AWS picks one. Set it for an `INBOUND` endpoint, so that the DNS servers on your network that forward to it keep the same targets.

    Adding or removing an entry changes the endpoint in place.
  EOT
  type = map(object({
    subnet_id = string
    ip        = optional(string)
  }))
  nullable = false

  validation {
    condition     = length(var.ip_addresses) >= 2 && length(var.ip_addresses) <= 10
    error_message = "ip_addresses needs between 2 and 10 entries."
  }

  validation {
    condition     = alltrue([for a in values(var.ip_addresses) : startswith(a.subnet_id, "subnet-")])
    error_message = "Each ip_addresses entry needs a subnet_id, such as subnet-0123456789abcdef0."
  }

  validation {
    condition = alltrue([
      for a in values(var.ip_addresses) :
      a.ip == null || (can(cidrhost("${coalesce(a.ip, "-")}/32", 0)) && !strcontains(coalesce(a.ip, "-"), ":"))
    ])
    error_message = "ip_addresses: ip must be an IPv4 address, such as 10.0.1.10."
  }

  validation {
    condition     = length(compact([for a in values(var.ip_addresses) : a.ip])) == length(distinct(compact([for a in values(var.ip_addresses) : a.ip])))
    error_message = "ip_addresses: each ip can be used only once."
  }
}

variable "protocols" {
  description = <<-EOT
    The protocols the endpoint uses for DNS queries:

    - `Do53` - Plain DNS on port 53, over UDP and TCP.
    - `DoH` - DNS over HTTPS, on TCP port 443.
    - `DoH-FIPS` - DNS over HTTPS with FIPS-validated cryptography, on TCP port 443. `INBOUND` endpoints only.

    The module opens only the ports these protocols need in `security_group_rules`. Changing the protocols changes the endpoint in place. Defaults to `["Do53"]`.
  EOT
  type        = set(string)
  default     = ["Do53"]
  nullable    = false

  validation {
    condition     = length(var.protocols) > 0 && alltrue([for p in var.protocols : contains(["Do53", "DoH", "DoH-FIPS"], p)])
    error_message = "protocols must be one or more of Do53, DoH and DoH-FIPS."
  }

  validation {
    condition     = var.direction == "INBOUND" || !contains(var.protocols, "DoH-FIPS")
    error_message = "DoH-FIPS is available only for INBOUND endpoints."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the endpoint and its security group in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. The VPC and subnets must be in that Region.
  EOT
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = <<-EOT
    Who the endpoint exchanges DNS traffic with. The module creates a security group for the endpoint with one rule per entry here, for each port that `protocols` needs (UDP and TCP 53 for `Do53`, TCP 443 for `DoH` and `DoH-FIPS`), and nothing else:

    - For an `INBOUND` endpoint, ingress rules: the sources allowed to send queries to the endpoint, such as the DNS servers on your network.
    - For an `OUTBOUND` endpoint, egress rules: the DNS servers the endpoint may forward queries to.

    With the default, `{}`, the endpoint can neither receive nor send queries. Replies need no rule of their own: security groups let them through. The keys are names you choose; they only identify each rule, so a security group created in the same configuration can be used.

    Each entry takes exactly one of:

    - `cidr_ipv4` - An IPv4 range, such as `10.0.0.0/16`.
    - `security_group_id` - A security group whose members are allowed, such as the group of DNS servers in a peered VPC.
    - `prefix_list_id` - A managed prefix list of ranges.

    and optionally:

    - `description` - (Optional) What the source or destination is. Defaults to the key.
  EOT
  type = map(object({
    cidr_ipv4         = optional(string)
    security_group_id = optional(string)
    prefix_list_id    = optional(string)
    description       = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for r in values(var.security_group_rules) :
      length([for v in [r.cidr_ipv4, r.security_group_id, r.prefix_list_id] : v if v != null]) == 1
    ])
    error_message = "Each security_group_rules entry needs exactly one of cidr_ipv4, security_group_id or prefix_list_id."
  }

  validation {
    condition = alltrue([
      for r in values(var.security_group_rules) :
      r.cidr_ipv4 == null || (can(cidrnetmask(r.cidr_ipv4)) && !strcontains(coalesce(r.cidr_ipv4, "-"), ":"))
    ])
    error_message = "security_group_rules: cidr_ipv4 must be an IPv4 range, such as 10.0.0.0/16."
  }
}

variable "vpc_id" {
  description = <<-EOT
    The ID of the VPC the endpoint is in, such as `vpc-0123456789abcdef0`. The module creates the endpoint's security group in it. Every subnet in `ip_addresses` must belong to it.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "vpc_id must be a VPC ID, such as vpc-0123456789abcdef0."
  }
}
