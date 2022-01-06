module "egress_only_internet_gateway_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["egress-only", "igw"]

  context = module.this.context
}

resource "aws_egress_only_internet_gateway" "default" {
  count = local.enabled && var.ipv6_egress_only_internet_gateway_enabled ? 1 : 0

  vpc_id = join("", data.aws_vpc.default.*.id)

  tags = merge(
    module.egress_only_internet_gateway_label.tags,
    {
      "Name" = module.egress_only_internet_gateway_label.id
    }
  )
}

resource "aws_route" "default_ipv6" {
  count                       = local.enabled && var.ipv6_egress_only_internet_gateway_enabled ? length(aws_route_table.private.*.id) : 0
  route_table_id              = element(aws_route_table.private.*.id, count.index)
  egress_only_gateway_id      = aws_egress_only_internet_gateway.default[0].id
  destination_ipv6_cidr_block = "::/0"
  depends_on                  = [aws_route_table.private]

  timeouts {
    create = var.aws_route_create_timeout
    delete = var.aws_route_delete_timeout
  }
}
