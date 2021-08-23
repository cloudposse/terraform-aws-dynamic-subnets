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

locals {
  vpc_ipv6_cidr_block         = join("", data.aws_vpc.default.*.ipv6_cidr_block)
  vpc_ipv6_blocks             = slice(split(":", local.vpc_ipv6_cidr_block), 0, 4)
  vpc_ipv6_last_group_hex     = parseint(local.vpc_ipv6_blocks[3], 16)
  first_3_ipv6_blocks         = join(":", slice(local.vpc_ipv6_blocks, 0, 3))
}

module "utils" {
  source  = "cloudposse/utils/aws"
  version = "0.8.1"
}
