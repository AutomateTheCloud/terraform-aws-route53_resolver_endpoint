resource "aws_security_group_rule" "udp_53-ingress" {
  count             = (length(var.allowed_cidrs) > 0 ? 1 : 0)
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
  provider          = aws.this
}

resource "aws_security_group_rule" "tcp_53-ingress" {
  count             = (length(var.allowed_cidrs) > 0 ? 1 : 0)
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
  provider          = aws.this
}

resource "aws_security_group_rule" "udp_853-ingress" {
  count             = (length(var.allowed_cidrs) > 0 ? 1 : 0)
  type              = "ingress"
  from_port         = 853
  to_port           = 853
  protocol          = "udp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
  provider          = aws.this
}

resource "aws_security_group_rule" "tcp_853-ingress" {
  count             = (length(var.allowed_cidrs) > 0 ? 1 : 0)
  type              = "ingress"
  from_port         = 853
  to_port           = 853
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
  provider          = aws.this
}

resource "aws_security_group_rule" "udp_53-egress" {
  count             = (length(var.allowed_cidrs) > 0 ? 1 : 0)
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
  provider          = aws.this
}

resource "aws_security_group_rule" "tcp_53-egress" {
  count             = (length(var.allowed_cidrs) > 0 ? 1 : 0)
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
  provider          = aws.this
}

resource "aws_security_group_rule" "udp_853-egress" {
  count             = (length(var.allowed_cidrs) > 0 ? 1 : 0)
  type              = "egress"
  from_port         = 853
  to_port           = 853
  protocol          = "udp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
  provider          = aws.this
}

resource "aws_security_group_rule" "tcp_853-egress" {
  count             = (length(var.allowed_cidrs) > 0 ? 1 : 0)
  type              = "egress"
  from_port         = 853
  to_port           = 853
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
  provider          = aws.this
}
