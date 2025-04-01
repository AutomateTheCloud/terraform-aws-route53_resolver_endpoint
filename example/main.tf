terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: Route53 - Resolver Endpoint
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

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value = module.route53_resolver_endpoint.metadata
}
