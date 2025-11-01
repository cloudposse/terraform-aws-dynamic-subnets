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

  use_az_ids = local.e && length(var.availability_zone_ids) > 0
  use_az_var = local.e && length(var.availability_zones) > 0
  # otherwise use_default_azs = local.e && !(local.use_az_ids || local.use_az_var)

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
  vpc_availability_zones = (
    var.max_subnet_count == 0 || var.max_subnet_count >= length(local.subnet_possible_availability_zones)
    ) ? (
    local.subnet_possible_availability_zones
  ) : slice(local.subnet_possible_availability_zones, 0, var.max_subnet_count)

  # Lookup the abbreviations for the availability zones we are using
  az_abbreviation_map_map = {
    short = "to_short"
    fixed = "to_fixed"
    full  = "identity"
  }

  az_abbreviation_map = module.utils.region_az_alt_code_maps[local.az_abbreviation_map_map[var.availability_zone_attribute_style]]

  ################### End of Availability Zone Normalization #######################

  #########################################
  # Configure subnet counts per AZ with backward compatibility

  # Use new variables if provided, otherwise fall back to legacy variables
  public_subnets_per_az_count  = coalesce(var.public_subnets_per_az_count, var.subnets_per_az_count)
  private_subnets_per_az_count = coalesce(var.private_subnets_per_az_count, var.subnets_per_az_count)

  public_subnets_per_az_names  = var.public_subnets_per_az_names != null ? var.public_subnets_per_az_names : var.subnets_per_az_names
  private_subnets_per_az_names = var.private_subnets_per_az_names != null ? var.private_subnets_per_az_names : var.subnets_per_az_names

  # Create separate availability zone lists for public and private subnets
  public_subnet_availability_zones  = local.public_enabled ? flatten([for z in local.vpc_availability_zones : [for net in range(0, local.public_subnets_per_az_count) : z]]) : []
  private_subnet_availability_zones = local.private_enabled ? flatten([for z in local.vpc_availability_zones : [for net in range(0, local.private_subnets_per_az_count) : z]]) : []

  public_subnet_az_count  = local.public_enabled ? length(local.public_subnet_availability_zones) : 0
  private_subnet_az_count = local.private_enabled ? length(local.private_subnet_availability_zones) : 0

  # For backward compatibility, subnet_az_count is the maximum of public and private counts
  # However, for NAT gateways and route tables, we need the count based on availability zones
  subnet_az_count = max(local.public_subnet_az_count, local.private_subnet_az_count)

  # Number of availability zones being used (for NAT gateways, one per AZ)
  vpc_az_count = length(local.vpc_availability_zones)

  # Create separate AZ abbreviation lists for public and private subnets
  public_subnet_az_abbreviations  = [for az in local.public_subnet_availability_zones : local.az_abbreviation_map[az]]
  private_subnet_az_abbreviations = [for az in local.private_subnet_availability_zones : local.az_abbreviation_map[az]]

  ################### End of subnet count configuration #######################

  #########################################
  # Configure subnet CIDRs

  # Figure out how many CIDRs to reserve. By default, we often reserve more CIDRs than we need so that
  # with future growth, we can add subnets without affecting existing subnets.
  existing_az_count = local.e ? length(data.aws_availability_zones.default[0].names) : 0
  max_az_count      = var.max_subnet_count == 0 ? local.existing_az_count : var.max_subnet_count

  # Calculate CIDR reservations separately for public and private subnets
  private_cidr_reservations = (local.private_enabled ? 1 : 0) * local.max_az_count * local.private_subnets_per_az_count
  public_cidr_reservations  = (local.public_enabled ? 1 : 0) * local.max_az_count * local.public_subnets_per_az_count
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

  public_dns64_enabled = local.public6_enabled && var.public_dns64_nat64_enabled
  # Set the default for private_dns64_enabled to true unless there is no IPv4 egress to enable it.
  private_dns64_enabled = local.private6_enabled && (
    var.private_dns64_nat64_enabled == null ? local.public4_enabled : var.private_dns64_nat64_enabled
  )

  public_route_table_enabled = local.public_enabled && var.public_route_table_enabled

  # Use `coalesce` to pick the highest priority value (null means go to next test)
  public_route_table_count = coalesce(
    # Do not bother with route tables if not creating subnets
    local.public_enabled ? null : 0,
    # Use provided route tables when provided
    length(var.public_route_table_ids) == 0 ? null : length(var.public_route_table_ids),
    # Do not create route tables when told not to:
    var.public_route_table_enabled ? null : 0,
    # Explicitly test var.public_route_table_per_subnet_enabled == true or == false
    # because both will be false when var.public_route_table_per_subnet_enabled == null
    var.public_route_table_per_subnet_enabled == true ? local.public_subnet_az_count : null,
    var.public_route_table_per_subnet_enabled == false ? 1 : null,
    local.public_dns64_enabled ? local.public_subnet_az_count : 1
  )

  create_public_route_tables = local.public_route_table_enabled && length(var.public_route_table_ids) == 0
  public_route_table_ids     = local.create_public_route_tables ? aws_route_table.public[*].id : var.public_route_table_ids

  private_route_table_enabled = local.private_enabled && var.private_route_table_enabled
  private_route_table_count   = local.private_route_table_enabled ? local.private_subnet_az_count : 0
  private_route_table_ids     = local.private_route_table_enabled ? aws_route_table.private[*].id : []

  # public and private network ACLs
  # Support deprecated var.public_network_acl_id
  public_open_network_acl_enabled = local.public_enabled && var.public_open_network_acl_enabled
  # Support deprecated var.private_network_acl_id
  private_open_network_acl_enabled = local.private_enabled && var.private_open_network_acl_enabled

  # A NAT device is needed to NAT from private IPv4 to public IPv4 or to perform NAT64 for IPv6.
  # An AWS NAT instance does not perform NAT64, and we choose not to try to support NAT64 via NAT instances at this time.
  nat_instance_useful = local.private4_enabled
  nat_gateway_useful  = local.nat_instance_useful || local.public_dns64_enabled || local.private_dns64_enabled

  # Convert subnet names to indices if names were specified
  # Creates a map of subnet name -> index for easy lookup
  public_subnet_name_to_index_map = {
    for idx, name in local.public_subnets_per_az_names : name => idx
  }

  # Resolve NAT Gateway placement: use names if provided, otherwise use indices
  nat_gateway_resolved_indices = var.nat_gateway_public_subnet_names != null ? [
    for name in var.nat_gateway_public_subnet_names :
    lookup(local.public_subnet_name_to_index_map, name, -1)
  ] : var.nat_gateway_public_subnet_indices

  # Calculate which public subnet indices to use for NAT placement
  # For each AZ (up to max_nats), and for each requested subnet index within that AZ,
  # calculate the global subnet index in the flattened aws_subnet.public list
  nat_gateway_public_subnet_indices = local.nat_gateway_useful ? flatten([
    for az_idx in range(min(local.vpc_az_count, var.max_nats)) : [
      for subnet_idx in local.nat_gateway_resolved_indices :
      az_idx * local.public_subnets_per_az_count + subnet_idx
      if subnet_idx >= 0 && subnet_idx < local.public_subnets_per_az_count
    ]
  ]) : []

  # NAT count is the number of NAT devices to create (based on AZs and indices requested)
  nat_count = length(local.nat_gateway_public_subnet_indices)

  # How many NATs are created per AZ
  nats_per_az = local.nat_count > 0 ? length(local.nat_gateway_resolved_indices) : 0

  # For each private route table, calculate which NAT device it should route to
  # This ensures each private subnet routes to a NAT in its own AZ
  # Used by both NAT Gateways and NAT Instances
  #
  # Example 1: 3 AZs, 3 private subnets per AZ, 1 NAT per AZ
  #   Route tables 0,1,2 (AZ0) → NAT 0
  #   Route tables 3,4,5 (AZ1) → NAT 1
  #   Route tables 6,7,8 (AZ2) → NAT 2
  #
  # Example 2: 3 AZs, 3 private subnets per AZ, 2 NATs per AZ
  #   Route tables 0,2 (AZ0, database & app2) → NAT 0
  #   Route table 1 (AZ0, app1) → NAT 1
  #   Route tables 3,5 (AZ1, database & app2) → NAT 2
  #   Route table 4 (AZ1, app1) → NAT 3
  #   Route tables 6,8 (AZ2, database & app2) → NAT 4
  #   Route table 7 (AZ2, app1) → NAT 5
  private_route_table_to_nat_map = local.nat_enabled && local.private4_enabled ? [
    for i in range(local.private_route_table_count) :
    # Calculate AZ index for this route table
    floor(i / local.private_subnets_per_az_count) * local.nats_per_az +
    # Distribute private subnets within the AZ across available NATs
    (i % local.private_subnets_per_az_count) % local.nats_per_az
  ] : []

  # For each public route table, calculate which NAT gateway it should route to (for NAT64)
  # This ensures each public subnet routes to a NAT in its own AZ
  public_route_table_to_nat_map = local.nat_gateway_enabled && local.public_dns64_enabled ? [
    for i in range(local.public_route_table_count) :
    # Calculate AZ index for this route table
    floor(i / local.public_subnets_per_az_count) * local.nats_per_az +
    # Distribute public subnets within the AZ across available NATs
    (i % local.public_subnets_per_az_count) % local.nats_per_az
  ] : []

  # It does not make sense to create both a NAT Gateway and a NAT instance, since they perform the same function
  # and occupy the same slot in a network routing table. Rather than try to create both,
  # we favor the more powerful NAT Gateway over the deprecated NAT Instance.
  # However, we do not want to force people to set `nat_gateway_enabled` to `false` to enable a NAT Instance,
  # so if `nat_instance_enabled` is set to true, we set the default for `nat_gateway_enabled` to `false`.
  nat_gateway_setting = var.nat_instance_enabled == true ? var.nat_gateway_enabled == true : !(
    var.nat_gateway_enabled == false # not true or null
  )
  nat_instance_setting = local.nat_gateway_setting ? false : var.nat_instance_enabled == true # not false or null

  # We suppress creating NATs if not useful, but choose to attempt to create NATs
  # when useful even if we know they will fail (e.g. due to no public subnets)
  # to provide useful feedback to users.
  nat_gateway_enabled  = local.nat_gateway_useful && local.nat_gateway_setting
  nat_instance_enabled = local.nat_instance_useful && local.nat_instance_setting
  nat_enabled          = local.nat_gateway_enabled || local.nat_instance_enabled
  need_nat_eips        = local.nat_enabled && length(var.nat_elastic_ips) == 0
  need_nat_eip_data    = local.nat_enabled && length(var.nat_elastic_ips) > 0
  nat_eip_allocations  = local.nat_enabled ? (local.need_nat_eips ? aws_eip.default[*].id : data.aws_eip.nat[*].id) : []

  need_nat_ami_id     = local.nat_instance_enabled && length(var.nat_instance_ami_id) == 0
  nat_instance_ami_id = local.need_nat_ami_id ? data.aws_ami.nat_instance[0].id : try(var.nat_instance_ami_id[0], "")

  # Locals for outputs
  az_private_subnets_map = { for z in local.vpc_availability_zones : z => (
    [for s in aws_subnet.private : s.id if s.availability_zone == z])
  }

  az_public_subnets_map = { for z in local.vpc_availability_zones : z => (
    [for s in aws_subnet.public : s.id if s.availability_zone == z])
  }

  az_private_route_table_ids_map = { for k, v in local.az_private_subnets_map : k => (
    [for t in aws_route_table_association.private : t.route_table_id if contains(v, t.subnet_id)])
  }

  az_public_route_table_ids_map = { for k, v in local.az_public_subnets_map : k => (
    [for t in aws_route_table_association.public : t.route_table_id if contains(v, t.subnet_id)])
  }

  named_private_subnets_map = { for i, s in local.private_subnets_per_az_names : s => (
    compact([for k, v in local.az_private_subnets_map : try(v[i], "")]))
  }

  named_public_subnets_map = { for i, s in local.public_subnets_per_az_names : s => (
    compact([for k, v in local.az_public_subnets_map : try(v[i], "")]))
  }

  named_private_route_table_ids_map = { for i, s in local.private_subnets_per_az_names : s => (
    compact([for k, v in local.az_private_route_table_ids_map : try(v[i], "")]))
  }

  named_public_route_table_ids_map = { for i, s in local.public_subnets_per_az_names : s => (
    compact([for k, v in local.az_public_route_table_ids_map : try(v[i], "")]))
  }

  named_private_subnets_stats_map = { for i, s in local.private_subnets_per_az_names : s => (
    [
      for k, v in local.az_private_route_table_ids_map : {
        az             = k
        route_table_id = try(v[i], "")
        subnet_id      = try(local.az_private_subnets_map[k][i], "")
      }
    ])
  }

  named_public_subnets_stats_map = { for i, s in local.public_subnets_per_az_names : s => (
    [
      for k, v in local.az_public_route_table_ids_map : {
        az             = k
        route_table_id = try(v[i], "")
        subnet_id      = try(local.az_public_subnets_map[k][i], "")
      }
    ])
  }
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
  count = local.need_nat_eip_data ? length(var.nat_elastic_ips) : 0

  public_ip = element(var.nat_elastic_ips, count.index)
}

resource "aws_eip" "default" {
  count = local.need_nat_eips ? local.nat_count : 0

  # `vpc` is deprecated in favor of `domain = "vpc"` in version 5 of the AWS provider.
  # However, the `domain` attribute is not available in version 4.
  # In order to support both version 4 and 5, we leave both out, which is valid for both versions,
  # but will break in accounts and regions where EC2-Classic is enabled.
  # Given that EC2-Classic was deprecated in 2013, this is unlikely to be a problem.
  # vpc = true     # provider version 4
  # domain = "vpc" # provider version 5

  tags = merge(
    module.nat_label.tags,
    {
      "Name" = format("%s%s%s", module.nat_label.id, local.delimiter, local.public_subnet_az_abbreviations[local.nat_gateway_public_subnet_indices[count.index]])
    }
  )

  lifecycle {
    create_before_destroy = true
  }
  #bridgecrew:skip=BC_AWS_NETWORKING_48: Skipping requirement for EIPs to be attached to EC2 instances because we are attaching to NAT Gateway.
}

module "utils" {
  source  = "cloudposse/utils/aws"
  version = "1.4.0"
}
