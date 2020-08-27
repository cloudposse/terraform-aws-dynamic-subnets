# Get object aws_vpc by vpc_id
data "aws_vpc" "default" {
  count = local.enabled ? 1 : 0
  id    = var.vpc_id
}

data "aws_availability_zones" "available" {
  count = local.enabled ? 1 : 0
}

locals {
  availability_zones_count = local.enabled ? length(var.availability_zones) : 0
  enabled                  = module.this.context.enabled
}

data "aws_eip" "nat_ips" {
  count     = local.enabled ? length(var.existing_nat_ips) : 0
  public_ip = element(var.existing_nat_ips, count.index)
}

locals {
  use_existing_eips = length(var.existing_nat_ips) > 0
}
