# Terraform module for Amazon Route 53 Resolver endpoints

Creates an Amazon Route 53 Resolver endpoint in a VPC, and a security group that controls which DNS servers it exchanges queries with. An inbound endpoint lets DNS servers on your network, or in another VPC, resolve names from the VPC, such as records in private hosted zones. An outbound endpoint lets the VPC forward queries to DNS servers elsewhere, through forwarding rules.

An endpoint created with only the required inputs uses plain DNS over IPv4, and cannot send or receive any query until you allow a network.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Direction | Required: `INBOUND` or `OUTBOUND` | `direction` |
| IP addresses | Required: at least 2, each in a subnet you choose; AWS picks the address unless you set one | `ip_addresses` |
| Network access | None: no query in or out | `security_group_rules` |
| Protocols | `Do53` (plain DNS on port 53) | `protocols` |
| Address type | IPv4 | |

## Usage

```hcl
module "resolver_inbound" {
  source  = "AutomateTheCloud/route53_resolver_endpoint/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Hybrid DNS"
    environment = "Production"
  }

  direction = "INBOUND"
  vpc_id    = "vpc-0123456789abcdef0"
  ip_addresses = {
    a = { subnet_id = "subnet-0123456789abcdef0", ip = "10.0.1.53" }
    b = { subnet_id = "subnet-0fedcba9876543210", ip = "10.0.2.53" }
  }

  security_group_rules = {
    data_center = { cidr_ipv4 = "192.168.0.0/16", description = "Data center DNS servers" }
  }
}
```

`details`, `direction`, `vpc_id` and `ip_addresses` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags on every resource.

The DNS servers on your network then forward queries for the VPC's domains to `10.0.1.53` and `10.0.2.53`. The addresses are also in `module.resolver_inbound.metadata.route53_resolver_endpoint.ip_address`.

The module uses your default `aws` provider and creates everything in that provider's Region. To create the endpoint somewhere else without configuring another provider, set `region`:

```hcl
module "resolver_us_west_2" {
  source  = "AutomateTheCloud/route53_resolver_endpoint/aws"
  version = "~> 1.0"

  region    = "us-west-2"
  details   = { scope = "Automate the Cloud", purpose = "Hybrid DNS", environment = "Production" }
  direction = "OUTBOUND"
  vpc_id    = "vpc-0abcdef0123456789"
  ip_addresses = {
    a = { subnet_id = "subnet-0abcdef0123456789" }
    b = { subnet_id = "subnet-09876543210fedcba" }
  }
}
```

The VPC and subnets must be in that Region too.

To use a provider configured for another account, pass it explicitly with `providers = { aws = aws.other_account }`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the endpoint belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Hybrid DNS"         # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at an endpoint in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the endpoint, its forwarding rules, its VPC and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Hybrid DNS"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "resolver_outbound" {
  source  = "AutomateTheCloud/route53_resolver_endpoint/aws"
  version = "~> 1.0"

  details   = local.details
  direction = "OUTBOUND"
  vpc_id    = "vpc-0123456789abcdef0"
  ip_addresses = {
    a = { subnet_id = "subnet-0123456789abcdef0" }
    b = { subnet_id = "subnet-0fedcba9876543210" }
  }
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Hybrid DNS` becomes `hybrid_dns`), and `machine`, lowercase letters and numbers only (`hybriddns`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.resolver_outbound.metadata.route53_resolver_endpoint.id` for a forwarding rule's `resolver_endpoint_id`, or `module.resolver_outbound.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`, given a VPC and two subnets.

- [Basic inbound endpoint](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint/tree/main/examples/basic): an endpoint that DNS servers on your network can forward queries to.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint/tree/main/examples/complete): an outbound endpoint with fixed addresses, DNS over HTTPS, and a forwarding rule that sends one domain's queries to DNS servers on your network.

## Things to know

### Cost

AWS bills an endpoint for each of its IP addresses, every hour it exists, whether it handles queries or not, plus a charge per query. See [Route 53 pricing](https://aws.amazon.com/route53/pricing/). Two addresses, the minimum, are enough for most endpoints.

AWS also limits how many endpoints an account can have in each Region (4 by default) and how many addresses each endpoint can have (6 by default). When an account is at its endpoint limit, the AWS provider keeps retrying the create, and fails if no endpoint is deleted before it times out. See [Route 53 Resolver quotas](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html#limits-api-entities-resolver) to check or raise them.

### Network access

The module's security group allows only what `security_group_rules` lists, on the ports `protocols` needs: UDP and TCP port 53 for `Do53`, and TCP port 443 for `DoH` and `DoH-FIPS`. An `INBOUND` endpoint gets ingress rules, from the sources that send it queries. An `OUTBOUND` endpoint gets egress rules, to the DNS servers it forwards to. Replies need no rule: security groups let them through.

To add a rule the module does not make, attach it to the group yourself with `aws_vpc_security_group_ingress_rule` or `aws_vpc_security_group_egress_rule` and `security_group_id = module.<name>.metadata.security_group.id`.

### Outbound endpoints need forwarding rules

An outbound endpoint forwards nothing on its own. A forwarding rule (`aws_route53_resolver_rule` with `rule_type = "FORWARD"`) names a domain, the DNS servers to send its queries to, and the endpoint to send them through, and a rule association applies it to a VPC. The [complete example](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint/tree/main/examples/complete) shows both. The [route53_resolver_rule module](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_rule) creates them too.

### IP addresses

Put the addresses in subnets in at least two Availability Zones, so the endpoint keeps answering when one zone is down. For an `INBOUND` endpoint, set each `ip`: the DNS servers on your network are configured with these addresses, and an address AWS picks changes whenever the endpoint is replaced. Adding, removing or changing an entry in `ip_addresses` changes the endpoint in place; the other addresses keep working.

### Settings that replace the endpoint

Changing `direction` or `vpc_id` replaces the endpoint. A replaced endpoint has a new ID and, unless you set them, new addresses. Forwarding rules that use the endpoint are replaced with it, together with their VPC associations, so the domains they forward are resolved normally until the new associations are in place, which takes a few minutes. Changing `details` renames the endpoint and retags everything in place. The security group keeps the name and description it was created with, because changing either would replace the group, and with it the endpoint.

### What the module does not cover

The endpoint uses IPv4 only: IPv6 and dual-stack endpoints are not supported. The `INBOUND_DELEGATION` direction is not supported either.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_direction"></a> [direction](#input_direction)

Description: Which way DNS queries go through the endpoint:

- `INBOUND` - Your network, or another VPC, sends queries to the endpoint, and Route 53 Resolver answers them from this VPC's view of DNS (private hosted zones, VPC names).
- `OUTBOUND` - Route 53 Resolver forwards queries from this VPC to DNS servers elsewhere, such as on your network. Forwarding rules (`aws_route53_resolver_rule`) decide which domains are forwarded; the endpoint only provides the network path.

Changing the direction replaces the endpoint.

Type: `string`

#### <a name="input_ip_addresses"></a> [ip_addresses](#input_ip_addresses)

Description: The network interfaces of the endpoint: one entry per IP address, each in a subnet of `vpc_id`. AWS requires at least 2. The AWS provider accepts at most 10, and an account quota allows 6 by default. Put them in subnets in different Availability Zones, so the endpoint keeps working when one zone fails. The keys are names you choose, such as the Availability Zone (`a`, `b`); they only identify each address, so a subnet created in the same configuration can be used.

Each entry takes:

- `subnet_id` - (Required) The subnet to create the address in.
- `ip` - (Optional) The IPv4 address to use, from the subnet's range. Without it, AWS picks one. Set it for an `INBOUND` endpoint, so that the DNS servers on your network that forward to it keep the same targets.

Adding or removing an entry changes the endpoint in place.

Type:

```hcl
map(object({
    subnet_id = string
    ip        = optional(string)
  }))
```

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: The ID of the VPC the endpoint is in, such as `vpc-0123456789abcdef0`. The module creates the endpoint's security group in it. Every subnet in `ip_addresses` must belong to it.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_protocols"></a> [protocols](#input_protocols)

Description: The protocols the endpoint uses for DNS queries:

- `Do53` - Plain DNS on port 53, over UDP and TCP.
- `DoH` - DNS over HTTPS, on TCP port 443.
- `DoH-FIPS` - DNS over HTTPS with FIPS-validated cryptography, on TCP port 443. `INBOUND` endpoints only.

The module opens only the ports these protocols need in `security_group_rules`. Changing the protocols changes the endpoint in place. Defaults to `["Do53"]`.

Type: `set(string)`

Default:

```json
[
  "Do53"
]
```

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the endpoint and its security group in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. The VPC and subnets must be in that Region.

Type: `string`

Default: `null`

#### <a name="input_security_group_rules"></a> [security_group_rules](#input_security_group_rules)

Description: Who the endpoint exchanges DNS traffic with. The module creates a security group for the endpoint with one rule per entry here, for each port that `protocols` needs (UDP and TCP 53 for `Do53`, TCP 443 for `DoH` and `DoH-FIPS`), and nothing else:

- For an `INBOUND` endpoint, ingress rules: the sources allowed to send queries to the endpoint, such as the DNS servers on your network.
- For an `OUTBOUND` endpoint, egress rules: the DNS servers the endpoint may forward queries to.

With the default, `{}`, the endpoint can neither receive nor send queries. Replies need no rule of their own: security groups let them through. The keys are names you choose; they only identify each rule, so a security group created in the same configuration can be used.

Each entry takes exactly one of:

- `cidr_ipv4` - An IPv4 range, such as `10.0.0.0/16`.
- `security_group_id` - A security group whose members are allowed, such as the group of DNS servers in a peered VPC.
- `prefix_list_id` - A managed prefix list of ranges.

and optionally:

- `description` - (Optional) What the source or destination is. Defaults to the key.

Type:

```hcl
map(object({
    cidr_ipv4         = optional(string)
    security_group_id = optional(string)
    prefix_list_id    = optional(string)
    description       = optional(string)
  }))
```

Default: `{}`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
- `route53_resolver_endpoint` - The endpoint, with its `id` (use it as `resolver_endpoint_id` in forwarding rules), `arn`, `name`, `direction`, `host_vpc_id`, `protocols`, `resolver_endpoint_type`, `security_group_ids`, `region`, `tags`, `tags_all`, and `ip_address`: one entry per address, with its `subnet_id`, `ip` and `ip_id`. The `ip` values are the addresses to forward queries to for an `INBOUND` endpoint.
- `security_group` - The endpoint's security group, with its `id`, `arn`, `name`, `name_prefix`, `description`, `vpc_id`, `owner_id`, `revoke_rules_on_delete`, `region`, `tags` and `tags_all`. Its rules are in the two entries below.
- `vpc_security_group_ingress_rule` - The ingress rules of an `INBOUND` endpoint, keyed `<entry>-<protocol>-<port>` (such as `on_premises-udp-53`), or `null` when there are none.
- `vpc_security_group_egress_rule` - The egress rules of an `OUTBOUND` endpoint, keyed the same way, or `null` when there are none.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
