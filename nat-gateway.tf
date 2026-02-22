module "nat_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["nat"]

  context = module.this.context
}

# Zonal NAT Gateways (traditional mode - one per AZ in public subnets)
resource "aws_nat_gateway" "default" {
  count = local.zonal_nat_gateway_useful ? local.nat_count : 0

  allocation_id = local.nat_eip_allocations[count.index]
  subnet_id     = aws_subnet.public[local.nat_gateway_public_subnet_indices[count.index]].id

  tags = merge(
    module.nat_label.tags,
    {
      "Name" = format("%s%s%s", module.nat_label.id, local.delimiter, local.public_subnet_az_abbreviations[local.nat_gateway_public_subnet_indices[count.index]])
    }
  )

  depends_on = [aws_eip_association.nat_instance]

  lifecycle {
    precondition {
      condition     = local.nat_gateway_names_valid
      error_message = "Invalid subnet names specified in `nat_gateway_public_subnet_names`: ${join(", ", local.nat_gateway_invalid_names)}. Valid names from `public_subnets_per_az_names` are: ${join(", ", local.public_subnets_per_az_names)}."
    }
  }
}

# Regional NAT Gateway (automatic multi-AZ expansion)
resource "aws_nat_gateway" "regional" {
  count = local.regional_nat_gateway_useful ? 1 : 0

  vpc_id            = local.vpc_id
  availability_mode = "regional"
  connectivity_type = "public"

  tags = merge(
    module.nat_label.tags,
    {
      "Name" = format("%s%s%s", module.nat_label.id, local.delimiter, "regional")
    }
  )

  depends_on = [aws_eip_association.nat_instance]
}

# If private IPv4 subnets and NAT Gateway are both enabled, create a
# default route from private subnet to NAT Gateway in each subnet
# Each private subnet routes to a NAT in its own AZ (zonal mode) or to the regional NAT (regional mode)
resource "aws_route" "nat4" {
  count = local.nat_gateway_enabled && local.private4_enabled ? local.private_route_table_count : 0

  route_table_id         = local.private_route_table_ids[count.index]
  nat_gateway_id         = local.nat_gateway_id_for_route[count.index]
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_route_table.private]

  timeouts {
    create = local.route_create_timeout
    delete = local.route_delete_timeout
  }
}

# If private IPv6 subnet needs NAT64 and NAT Gateway is enabled, create a
# NAT64 route from private subnet to NAT Gateway in each subnet
# Each private subnet routes to a NAT in its own AZ (zonal mode) or to the regional NAT (regional mode)
resource "aws_route" "private_nat64" {
  count = local.nat_gateway_enabled && local.private_dns64_enabled ? local.private_route_table_count : 0

  route_table_id              = local.private_route_table_ids[count.index]
  nat_gateway_id              = local.nat_gateway_id_for_route[count.index]
  destination_ipv6_cidr_block = local.nat64_cidr
  depends_on                  = [aws_route_table.private]

  timeouts {
    create = local.route_create_timeout
    delete = local.route_delete_timeout
  }
}

# If public IPv6 subnet needs NAT64 and NAT Gateway is enabled, create a
# NAT64 route from public subnet to NAT Gateway in each subnet
# Each public subnet routes to a NAT in its own AZ (zonal mode) or to the regional NAT (regional mode)
resource "aws_route" "public_nat64" {
  count = local.nat_gateway_enabled && local.public_dns64_enabled ? local.public_route_table_count : 0

  route_table_id              = local.public_route_table_ids[count.index]
  nat_gateway_id              = local.nat_gateway_id_for_public_route[count.index]
  destination_ipv6_cidr_block = local.nat64_cidr
  depends_on                  = [aws_route_table.public]

  timeouts {
    create = local.route_create_timeout
    delete = local.route_delete_timeout
  }
}
