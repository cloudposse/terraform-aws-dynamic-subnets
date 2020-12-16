variable "region" {
  type        = string
  description = "AWS region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones where subnets will be created"
}

variable "existing_nat_ips" {
  type        = list(string)
  default     = []
  description = "Existing Elastic IPs to attach to the NAT Gateway or Instance instead of creating a new one."
}
