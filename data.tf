data "aws_subnets" "this" {
  count = (var.subnet_network_tag != "" ? 1 : 0)
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "tag:Network"
    values = [var.subnet_network_tag]
  }
  provider = aws.this
}

data "aws_vpc" "this" {
  id       = var.vpc_id
  provider = aws.this
}
