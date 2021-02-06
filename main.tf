# Get object aws_vpc by vpc_id
data "aws_vpc" "default" {
  count = local.enabled ? 1 : 0
  id    = var.vpc_id
}

data "aws_availability_zones" "available" {
  count = local.enabled_count
}

locals {
  availability_zones_count = local.enabled ? length(var.availability_zones) : 0
  enabled                  = module.this.enabled
  enabled_count            = local.enabled ? 1 : 0
  delimiter                = module.this.delimiter
}

data "aws_eip" "nat_ips" {
  count     = local.enabled ? length(var.nat_elastic_ips) : 0
  public_ip = element(var.nat_elastic_ips, count.index)
}

locals {
  use_existing_eips = length(var.nat_elastic_ips) > 0
  map_map = {
    short = "to_short"
    fixed = "to_fixed"
    full  = "identity"
  }
  az_map = module.utils.region_az_alt_code_maps[local.map_map[var.availability_zone_attribute_style]]
}

module "utils" {
  source  = "cloudposse/utils/aws"
  version = "0.4.0"
}
