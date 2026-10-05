# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The security group of the endpoint. It allows DNS to or from the entries in
# security_group_rules and nothing else; replies need no rule of their own.
resource "aws_security_group" "this" {
  region                 = var.region
  name_prefix            = "${local.name}-"
  description            = "${local.scope.name} - ${local.purpose.name} [${local.environment.name}] (${local.aws.region.name}): Route 53 Resolver ${local.direction.name} endpoint"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(local.tags, { Name = local.name })

  lifecycle {
    # A new VPC replaces the group. Creating the new group first lets the endpoint move
    # to it before the old one, which it still uses, is deleted.
    create_before_destroy = true

    # The name and description change whenever details does, and either change would
    # replace the group, and with it the endpoint and its IP addresses. They are set
    # once; the Name tag follows details instead.
    ignore_changes = [name_prefix, description]
  }
}
