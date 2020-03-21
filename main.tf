# Get object aws_vpc by vpc_id
data "aws_vpc" "default" {
  count = var.enabled ? 1 : 0
  id    = var.vpc_id
}

data "aws_availability_zones" "available" {
  count = var.enabled ? 1 : 0
}

locals {
  availability_zones_count = var.enabled ? length(var.availability_zones) : 0
  enabled                  = var.enabled ? 1 : 0
}

data "aws_eip" "nat_ips" {
  count     = length(var.nat_gateway_ips)
  public_ip = element(var.nat_gateway_ips, count.index)
}

locals {
  use_existing_eips = length(var.nat_gateway_ips) > 0
}
