# Process all the optional inputs into a fully fleshed out configuration
# the rest of the code can consume.

locals {
  enabled = module.this.enabled && (var.public_subnets_enabled || var.private_subnets_enabled) && (var.ipv4_enabled || var.ipv6_enabled)

  # We are going to reference `enabled` a *lot*, so abbreviate it
  e = local.enabled

  # Use delimiter shortcut for creating AZ-based Names/IDs
  delimiter = module.this.delimiter

  # The RFC 6052 "well known" NAT64 CIDR
  nat64_cidr = "64:ff9b::/96"

  # In case we later decide to compute it
  vpc_id = var.vpc_id

  #####################################################################
  ## Determine the set of availability zones in which to deploy subnets
  #  Priority is
  #  - availability_zone_ids
  #  - availability_zones
  #  - data.aws_availability_zones.default

  use_az_ids      = local.e && length(var.availability_zone_ids) > 0
  use_az_var      = local.e && length(var.availability_zones) > 0
  use_default_azs = local.e && !(local.use_az_ids || local.use_az_var)

  # Create a map of AZ IDs to AZ names (and the reverse),
  # but fail safely, because AZ IDs are not always available.
  az_id_map   = try(zipmap(data.aws_availability_zones.default[0].zone_ids, data.aws_availability_zones.default[0].names), {})
  az_name_map = try(zipmap(data.aws_availability_zones.default[0].names, data.aws_availability_zones.default[0].zone_ids), {})

  # Create a map of options, not necessarily all filled in, to separate creating the option
  # from selecting the option, making the code easier to understand.
  az_option_map = {
    from_az_ids = local.e ? [for id in var.availability_zone_ids : local.az_id_map[id]] : []
    from_az_var = local.e ? var.availability_zones : []
    all_azs     = local.e ? sort(data.aws_availability_zones.default[0].names) : []
  }

  subnet_availability_zone_option = local.use_az_ids ? "from_az_ids" : (
    local.use_az_var ? "from_az_var" : "all_azs"
  )

  subnet_possible_availability_zones = local.az_option_map[local.subnet_availability_zone_option]

  # Adjust list according to `max_subnet_count`
  subnet_availability_zones = slice(local.subnet_possible_availability_zones, 0, var.max_subnet_count > 0 ? var.max_subnet_count : length(local.subnet_possible_availability_zones))

  subnet_az_count = local.e ? length(local.subnet_availability_zones) : 0
  subnet_count    = ((local.public_enabled ? 1 : 0) + (local.private_enabled ? 1 : 0)) * local.subnet_az_count

  # Lookup the abbreviations for the availability zones we are using
  az_abbreviation_map_map = {
    short = "to_short"
    fixed = "to_fixed"
    full  = "identity"
  }
  az_abbreviation_map = module.utils.region_az_alt_code_maps[local.az_abbreviation_map_map[var.availability_zone_attribute_style]]

  subnet_az_abbreviations = [for az in local.subnet_availability_zones : local.az_abbreviation_map[az]]

  ################### End of Availability Zone Normalization #######################

  #########################################
  # Configure subnet CIDRs

  # Figure out how many CIDRs to reserve. By default, we often reserve more CIDRs than we need so that
  # with future growth, we can add subnets without affecting existing subnets.
  existing_az_count         = local.e ? length(data.aws_availability_zones.default[0].names) : 0
  base_cidr_reservations    = var.max_subnet_count == 0 ? local.existing_az_count : var.max_subnet_count
  private_cidr_reservations = (local.private_enabled ? 1 : 0) * local.base_cidr_reservations
  public_cidr_reservations  = (local.public_enabled ? 1 : 0) * local.base_cidr_reservations
  cidr_reservations         = local.private_cidr_reservations + local.public_cidr_reservations


  # Calculate how many bits are required to designate a subnet,
  # but also prevent errors like log(0) when things are disabled.
  required_ipv4_subnet_bits = local.e ? ceil(log(local.cidr_reservations, 2)) : 1
  required_ipv6_subnet_bits = 8 # Currently the only value allowed by AWS

  supplied_ipv4_private_subnet_cidrs = try(var.ipv4_cidrs[0].private, [])
  supplied_ipv4_public_subnet_cidrs  = try(var.ipv4_cidrs[0].public, [])

  supplied_ipv6_private_subnet_cidrs = try(var.ipv6_cidrs[0].private, [])
  supplied_ipv6_public_subnet_cidrs  = try(var.ipv6_cidrs[0].public, [])

  compute_ipv4_cidrs = local.ipv4_enabled && (length(local.supplied_ipv4_private_subnet_cidrs) + length(local.supplied_ipv4_public_subnet_cidrs)) == 0
  compute_ipv6_cidrs = local.ipv6_enabled && (length(local.supplied_ipv6_private_subnet_cidrs) + length(local.supplied_ipv6_public_subnet_cidrs)) == 0
  need_vpc_data      = (local.compute_ipv4_cidrs && length(var.ipv4_cidr_block) == 0) || (local.compute_ipv6_cidrs && length(var.ipv6_cidr_block) == 0)

  base_ipv4_cidr_block = length(var.ipv4_cidr_block) > 0 ? var.ipv4_cidr_block[0] : (local.need_vpc_data ? data.aws_vpc.default[0].cidr_block : "")
  base_ipv6_cidr_block = length(var.ipv6_cidr_block) > 0 ? var.ipv6_cidr_block[0] : (local.need_vpc_data ? data.aws_vpc.default[0].ipv6_cidr_block : "")

  # For backward compatibility, private subnets get the lower CIDR range
  ipv4_private_subnet_cidrs = local.compute_ipv4_cidrs ? [
    for net in range(0, local.private_cidr_reservations) : cidrsubnet(local.base_ipv4_cidr_block, local.required_ipv4_subnet_bits, net)
  ] : local.supplied_ipv4_private_subnet_cidrs
  ipv4_public_subnet_cidrs = local.compute_ipv4_cidrs ? [
    for net in range(local.private_cidr_reservations, local.cidr_reservations) : cidrsubnet(local.base_ipv4_cidr_block, local.required_ipv4_subnet_bits, net)
  ] : local.supplied_ipv4_public_subnet_cidrs

  ipv6_private_subnet_cidrs = local.compute_ipv6_cidrs ? [
    for net in range(0, local.private_cidr_reservations) : cidrsubnet(local.base_ipv6_cidr_block, local.required_ipv6_subnet_bits, net)
  ] : local.supplied_ipv6_private_subnet_cidrs
  ipv6_public_subnet_cidrs = local.compute_ipv6_cidrs ? [
    for net in range(local.private_cidr_reservations, local.cidr_reservations) : cidrsubnet(local.base_ipv6_cidr_block, local.required_ipv6_subnet_bits, net)
  ] : local.supplied_ipv6_public_subnet_cidrs

  ################### End of CIDR configuration #######################

  ##########################################
  # Tick off the list of things to create

  public_enabled  = local.e && var.public_subnets_enabled
  private_enabled = local.e && var.private_subnets_enabled
  ipv4_enabled    = local.e && var.ipv4_enabled
  ipv6_enabled    = local.e && var.ipv6_enabled

  igw_configured = length(var.igw_id) > 0
  # ipv6_egress_only_configured indicates if the configuration *supports* the use of
  # an IPv6 Egress-only Internet Gateway, not if it *requires* its use.
  ipv6_egress_only_configured = local.ipv6_enabled && length(var.ipv6_egress_only_igw_id) > 0

  public4_enabled  = local.public_enabled && local.ipv4_enabled
  public6_enabled  = local.public_enabled && local.ipv6_enabled
  private4_enabled = local.private_enabled && local.ipv4_enabled
  private6_enabled = local.private_enabled && local.ipv6_enabled

  public_dns64_enabled  = local.public6_enabled && var.public_dns64_enabled
  private_dns64_enabled = local.private6_enabled && var.private_dns64_enabled

  public_network_route_enabled = local.public_enabled && var.public_network_route_enabled
  public_network_table_enabled = local.public_network_route_enabled && (length(var.public_route_table_id) == 0 || local.public_dns64_enabled)
  public_network_table_count   = local.public_network_table_enabled ? (local.public_dns64_enabled ? local.subnet_az_count : 1) : 0
  public_network_table_ids     = local.public_network_table_enabled ? aws_route_table.public.*.id : var.public_route_table_id

  private_network_route_enabled = local.private_enabled && (local.nat_enabled || local.ipv6_egress_only_configured) && var.private_network_route_enabled
  private_network_table_enabled = local.private_network_route_enabled
  private_network_table_count   = local.private_network_table_enabled ? local.subnet_az_count : 0
  private_network_table_ids     = local.private_network_table_enabled ? aws_route_table.private.*.id : []

  # public and private network ACLs
  # Support deprecated var.public_network_acl_id
  public_open_network_acl_enabled = local.public_enabled && (length(var.public_network_acl_id) > 0 ? false : var.public_open_network_acl_enabled)
  # Support deprecated var.private_network_acl_id
  private_open_network_acl_enabled = local.private_enabled && (length(var.private_network_acl_id) > 0 ? false : var.private_open_network_acl_enabled)

  # A NAT device is needed to NAT from private IPv4 to public IPv4 or to perform NAT64 for IPv6,
  # but since it must be placed in a public subnet, we consider it not required if we are not creating public subnets.
  nat_required        = local.public_enabled && (local.private4_enabled || local.public_dns64_enabled)
  nat_gateway_enabled = local.nat_required && var.nat_gateway_enabled
  # An AWS NAT instance does not perform NAT64, but we allow for one anyway because
  # the user can supply their own NAT instance AMI that does support it.
  nat_instance_enabled = local.nat_required && var.nat_instance_enabled
  nat_enabled          = local.nat_gateway_enabled || local.nat_instance_enabled
  need_nat_eips        = local.nat_enabled && length(var.nat_elastic_ips) == 0
  need_nat_eip_data    = local.nat_enabled && length(var.nat_elastic_ips) > 0
  nat_eip_allocations  = local.nat_enabled ? (local.need_nat_eips ? aws_eip.default.*.id : data.aws_eip.nat.*.id) : []

  need_nat_ami_id     = local.nat_instance_enabled && length(var.nat_instance_ami_id) == 0
  nat_instance_ami_id = local.need_nat_ami_id ? data.aws_ami.nat_instance[0].id : try(var.nat_instance_ami_id[0], "")

}

data "aws_availability_zones" "default" {
  count = local.enabled ? 1 : 0

  # Filter out Local Zones. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones#by-filter
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_vpc" "default" {
  count = local.need_vpc_data ? 1 : 0

  id = local.vpc_id
}

data "aws_eip" "nat" {
  count     = local.need_nat_eip_data ? length(var.nat_elastic_ips) : 0
  public_ip = element(var.nat_elastic_ips, count.index)
}


resource "aws_eip" "default" {
  count = local.need_nat_eips ? local.subnet_az_count : 0
  vpc   = true

  tags = merge(
    module.nat_label.tags,
    {
      "Name" = format("%s%s%s", module.nat_label.id, local.delimiter, local.subnet_az_abbreviations[count.index])
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

module "utils" {
  source  = "cloudposse/utils/aws"
  version = "0.8.1"
}
