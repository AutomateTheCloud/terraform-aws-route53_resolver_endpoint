variable "allowed_cidrs" {
  description = "Allowed CIDRs"
  type        = list(any)
  default     = []
}

variable "direction" {
  description = "The direction of DNS queries to or from the Route 53 Resolver endpoint (INBOUND or OUTBOUND)"
  type        = string
  default     = "OUTBOUND"
}

variable "ip_address_assignment" {
  description = "IP Address assignment per Subnet (example: { subnet-09df4d2511ead488b = \"192.168.0.11\" }"
  type        = map(any)
  default     = {}
}

variable "subnets" {
  description = "Subnet IDs (not needed if specifying Network Tag)"
  type        = list(any)
  default     = []
}

variable "subnet_network_tag" {
  description = "Subnet Network Tag (not needed if specifying Subnet IDs)"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}
