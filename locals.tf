locals {
  subnet = {
    ids = (var.subnet_network_tag != "" ? distinct(compact(concat(tolist(data.aws_subnets.this[0].ids), var.subnets))) : var.subnets)
  }

  direction = {
    name = upper(var.direction) == "INBOUND" ? "Inbound" : "Outbound"
    abbr = upper(var.direction) == "INBOUND" ? "inbound" : "outbound"
  }
}
