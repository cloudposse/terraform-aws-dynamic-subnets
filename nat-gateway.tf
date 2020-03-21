module "nat_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  context    = module.label.context
  attributes = distinct(compact(concat(module.label.attributes, ["nat"])))
}

locals {
  nat_gateways_count = var.enabled && var.nat_gateway_enabled ? local.availability_zones_count : 0
  use_existing_eips  = length(var.nat_gateway_ips) > 0
  eips_allocations   = local.use_existing_eips ? data.aws_eip.nat_ips.*.id : aws_eip.default.*.id
  nat_gateways_count = var.nat_gateway_enabled && !local.use_existing_eips ? length(var.availability_zones) : 0
}

data "aws_eip" "nat_ips" {
  count     = length(var.nat_gateway_ips)
  public_ip = element(var.nat_gateway_ips, count.index)
}

resource "aws_eip" "default" {
  count = local.nat_gateways_count
  vpc   = true

  tags = merge(
    module.private_label.tags,
    {
      "Name" = format(
        "%s%s%s",
        module.private_label.id,
        var.delimiter,
        replace(
          element(var.availability_zones, count.index),
          "-",
          var.delimiter
        )
      )
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "default" {
  count         = local.nat_gateways_count
  allocation_id = element(local.eips_allocations, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = merge(
    module.nat_label.tags,
    {
      "Name" = format(
        "%s%s%s",
        module.nat_label.id,
        var.delimiter,
        replace(
          element(var.availability_zones, count.index),
          "-",
          var.delimiter
        )
      )
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route" "default" {
  count                  = local.nat_gateways_count
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  nat_gateway_id         = element(aws_nat_gateway.default.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_route_table.private]
}
