# Basic inbound endpoint

An inbound Amazon Route 53 Resolver endpoint with two or more IP addresses, which the DNS servers on your network can forward queries to. They can then resolve names in the VPC, such as records in its private hosted zones. The endpoint accepts plain DNS (UDP and TCP port 53) from the range you give, and nothing else.

AWS picks each address. For a long-lived endpoint, set them in `ip_addresses` instead, so they stay the same if the endpoint is ever replaced.

## Run it

Choose a VPC and one subnet in each of two or more Availability Zones, and the IPv4 range of your DNS servers:

```shell
terraform init
terraform apply -var 'vpc_id=vpc-0123456789abcdef0' -var 'subnet_ids=["subnet-0123456789abcdef0","subnet-0fedcba9876543210"]' -var 'dns_server_cidr=192.168.0.0/24'
```

The `ip_addresses` output lists the addresses to configure as forwarders on your DNS servers. Your network must reach the VPC, through AWS Site-to-Site VPN or AWS Direct Connect.

The endpoint is billed for each address, every hour. Remove it with `terraform destroy` and the same `-var` options.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_dns_server_cidr"></a> [dns_server_cidr](#input_dns_server_cidr)

Description: IPv4 range of the DNS servers on your network that will forward queries to the endpoint

Type: `string`

#### <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)

Description: IDs of two or more subnets of the VPC, each in a different Availability Zone

Type: `list(string)`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of the VPC to create the endpoint in

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_ip_addresses"></a> [ip_addresses](#output_ip_addresses)

Description: The addresses to forward queries to
<!-- END_TF_DOCS -->
