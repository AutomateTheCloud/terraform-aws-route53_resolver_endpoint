# AWS - Route53 - Resolver Endpoint - Terraform Module
Terraform module to create Route53 Resolver Endpoints (AutomateTheCloud model)

***

## Usage
```hcl
module "route53_resolver_endpoint" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope               = "Demo"
    purpose             = "Resolver Endpoint"
    environment         = "dev"
    additional_tags = {
      "Project"         = "Project Name"
      "ProjectID"       = "123456789"
      "Contact"         = "David Singer - david.singer@example.com"
    }
  }

  direction     = "OUTBOUND"
  allowed_cidrs = [ "0.0.0.0/0" ]

  # ip_address_assignment = {
    # subnet-0123456789012345a = "10.75.224.201"
    # subnet-0123456789012345b = "10.75.225.201"
    # subnet-0123456789012345c = "10.75.226.201"
  # }

  # subnets = [
    # "subnet-0123456789012345a",
    # "subnet-0123456789012345b",
    # "subnet-0123456789012345c"
  # ]
  subnet_network_tag = "private"
  vpc_id             = "vpc-00000000000000001"
}
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `allowed_cidrs` | Allowed CIDRs | `list` | `[]` |
| `direction` | The direction of DNS queries to or from the Route 53 Resolver endpoint (INBOUND or OUTBOUND) | `string` | `OUTBOUND` |
| `ip_address_assignment` | IP Address assignment per Subnet (example: { subnet-09df4d2511ead488b = "192.168.0.11" } | `map` | `{}` |
| `subnets` | Subnet IDs (not needed if specifying Network Tag) | `list` | `[]` |
| `subnet_network_tag` | Subnet Network Tag (not needed if specifying Subnet IDs) | `string` | |
| `vpc_id` | VPC ID | `string` | |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#Abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object server? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#Abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#Abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#Additional-Tags) for resources | `map` | `[]` |

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `aws.account.id` | AWS Account ID |
| `aws.region.name` | AWS Region name, example: `us-east-1` |
| `aws.region.abbr` | AWS Region four letter abbreviation, example: `use1` |
| `aws.region.description` | AWS Region description, example: `US East (N. Virginia)` |
| `route53_resolver_endpoint.id` | Route53 - Resolver Endpoint: ID |
| `route53_resolver_endpoint.arn` | Route53 - Resolver Endpoint: ARN |
| `route53_resolver_endpoint.name` | Route53 - Resolver Endpoint: Name |
| `route53_resolver_endpoint.direction` | Route53 - Resolver Endpoint: Direction |
| `route53_resolver_endpoint.host_vpc_id` | Route53 - Resolver Endpoint: Host VPC ID |
| `route53_resolver_endpoint.ip_address` | Route53 - Resolver Endpoint: List of Resolver IP Addresses with Subnet IDs |
| `route53_resolver_endpoint.security_group_ids` | Route53 - Resolver Endpoint: Security Group IDs |
| `security_group.id` | Security Group: ID |
| `security_group.arn` | Security Group: ARN |
| `security_group.name` | Security Group: Name |

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |
