module "nat_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["nat"]

  context = module.this.context
}

resource "aws_nat_gateway" "default" {
  count = local.nat_gateway_enabled ? local.nat_count : 0

  allocation_id = local.nat_eip_allocations[count.index]
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    module.nat_label.tags,
    {
      "Name" = format("%s%s%s", module.nat_label.id, local.delimiter, local.subnet_az_abbreviations[count.index])
    }
  )

  depends_on = [aws_eip_association.nat_instance]
}

# If private IPv4 subnets and NAT Gateway are both enabled, create a
# default route from private subnet to NAT Gateway in each subnet
resource "aws_route" "nat4" {
  count = local.nat_gateway_enabled && local.private4_enabled ? local.private_route_table_count : 0

  route_table_id         = local.private_route_table_ids[count.index]
  nat_gateway_id         = element(aws_nat_gateway.default[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_route_table.private]

  timeouts {
    create = local.route_create_timeout
    delete = local.route_delete_timeout
  }
}

# If private IPv6 subnet needs NAT64 and NAT Gateway is enabled, create a
# NAT64 route from private subnet to NAT Gateway in each subnet
resource "aws_route" "private_nat64" {
  count = local.nat_gateway_enabled && local.private_dns64_enabled ? local.private_route_table_count : 0

  route_table_id              = local.private_route_table_ids[count.index]
  nat_gateway_id              = element(aws_nat_gateway.default[*].id, count.index)
  destination_ipv6_cidr_block = local.nat64_cidr
  depends_on                  = [aws_route_table.private]

  timeouts {
    create = local.route_create_timeout
    delete = local.route_delete_timeout
  }
}

# If public IPv6 subnet needs NAT64 and NAT Gateway is enabled, create a
# NAT64 route from private subnet to NAT Gateway in each subnet
resource "aws_route" "public_nat64" {
  count = local.nat_gateway_enabled && local.public_dns64_enabled ? local.public_route_table_count : 0

  route_table_id              = local.public_route_table_ids[count.index]
  nat_gateway_id              = element(aws_nat_gateway.default[*].id, count.index)
  destination_ipv6_cidr_block = local.nat64_cidr
  depends_on                  = [aws_route_table.public]

  timeouts {
    create = local.route_create_timeout
    delete = local.route_delete_timeout
  }
}
