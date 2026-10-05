# Complete

An outbound Amazon Route 53 Resolver endpoint, and a forwarding rule that uses it. Queries from the VPC for one domain, such as `corp.example.com`, go through the endpoint to the DNS servers on your network; every other query is answered by Route 53 Resolver as usual.

It shows most of the module's options:

- Fixed IP addresses, one per subnet.
- Plain DNS and DNS over HTTPS (`protocols = ["Do53", "DoH"]`), so the security group allows UDP and TCP port 53 and TCP port 443.
- Egress rules to each DNS server's address only.
- An abbreviation override (`environment_abbr = "dev"`) and an additional tag.

## Run it

Choose a VPC, a free address in each of two or more subnets in different Availability Zones, the domain to forward, and your DNS servers:

```shell
terraform init
terraform apply \
  -var 'vpc_id=vpc-0123456789abcdef0' \
  -var 'addresses={"subnet-0123456789abcdef0"="10.0.1.53","subnet-0fedcba9876543210"="10.0.2.53"}' \
  -var 'domain_name=corp.example.com' \
  -var 'dns_servers=["192.168.0.10","192.168.0.11"]'
```

Instances in the VPC then resolve names under `corp.example.com` through your DNS servers. Your network must reach the VPC, through AWS Site-to-Site VPN or AWS Direct Connect. To forward with DNS over HTTPS instead, set the rule's `target_ip` `protocol` to `DoH` and `port` to `443`.

The endpoint is billed for each address, every hour. Remove everything with `terraform destroy` and the same `-var` options.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_addresses"></a> [addresses](#input_addresses)

Description: Two or more IPv4 addresses for the endpoint, each in a subnet of the VPC, keyed by subnet ID; one subnet per Availability Zone

Type: `map(string)`

#### <a name="input_dns_servers"></a> [dns_servers](#input_dns_servers)

Description: IPv4 addresses of the DNS servers on your network that answer for domain_name

Type: `list(string)`

#### <a name="input_domain_name"></a> [domain_name](#input_domain_name)

Description: The domain whose queries are forwarded, such as corp.example.com

Type: `string`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of the VPC to create the endpoint in

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_endpoint_id"></a> [endpoint_id](#output_endpoint_id)

Description: ID of the outbound endpoint, for more forwarding rules

#### <a name="output_rule_id"></a> [rule_id](#output_rule_id)

Description: ID of the forwarding rule, to share with other accounts or associate with other VPCs
<!-- END_TF_DOCS -->
