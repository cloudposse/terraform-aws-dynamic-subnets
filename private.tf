module "private_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = [var.private_label]
  tags = merge(
    var.private_subnets_additional_tags,
    var.subnet_type_tag_key != null && var.subnet_type_tag_value_format != null ? { (var.subnet_type_tag_key) = format(var.subnet_type_tag_value_format, var.private_label) } : {}
  )

  context = module.this.context
}

resource "aws_subnet" "private" {
  count = local.private_enabled ? local.subnet_az_count : 0

  vpc_id            = local.vpc_id
  availability_zone = local.subnet_availability_zones[count.index]

  cidr_block      = local.private4_enabled ? local.ipv4_private_subnet_cidrs[count.index] : null
  ipv6_cidr_block = local.private6_enabled ? local.ipv6_private_subnet_cidrs[count.index] : null
  ipv6_native     = local.private6_enabled && !local.private4_enabled

  tags = merge(
    module.private_label.tags,
    {
      "Name" = format("%s%s%s", module.private_label.id, local.delimiter, local.subnet_az_abbreviations[count.index])
    }
  )

  assign_ipv6_address_on_creation = local.private6_enabled ? var.private_assign_ipv6_address_on_creation : null
  enable_dns64                    = local.private6_enabled ? local.private_dns64_enabled : null

  enable_resource_name_dns_a_record_on_launch    = local.private4_enabled ? var.ipv4_private_instance_hostnames_enabled : null
  enable_resource_name_dns_aaaa_record_on_launch = local.private6_enabled ? var.ipv6_private_instance_hostnames_enabled || !local.private4_enabled : null

  private_dns_hostname_type_on_launch = local.private4_enabled ? var.ipv4_private_instance_hostname_type : null

  lifecycle {
    # Ignore tags added by kops or kubernetes
    ignore_changes = [tags.kubernetes, tags.SubnetType]
  }

  timeouts {
    create = var.subnet_create_timeout
    delete = var.subnet_delete_timeout
  }
}

resource "aws_route_table" "private" {
  # Currently private_route_table_count == subnet_az_count,
  # but keep parallel to public route table configuration
  count = local.private_route_table_count

  vpc_id = local.vpc_id

  tags = merge(
    module.private_label.tags,
    {
      "Name" = format("%s%s%s", module.private_label.id, local.delimiter, local.subnet_az_abbreviations[count.index])
    }
  )
}

resource "aws_route" "private6" {
  count = local.ipv6_egress_only_configured ? local.private_route_table_count : 0

  route_table_id              = local.private_route_table_ids[count.index]
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = var.ipv6_egress_only_igw_id[0]

  timeouts {
    create = local.route_create_timeout
    delete = local.route_delete_timeout
  }
}

resource "aws_route_table_association" "private" {
  count = local.private_route_table_enabled ? local.subnet_az_count : 0

  subnet_id = aws_subnet.private[count.index].id
  # Use element() to "wrap around" and allow for a single table to be associated with all subnets
  route_table_id = element(local.private_route_table_ids, count.index)
}

resource "aws_network_acl" "private" {
  count = local.private_open_network_acl_enabled ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.private.*.id

  tags = module.private_label.tags
}

resource "aws_network_acl_rule" "private4_ingress" {
  count = local.private_open_network_acl_enabled && local.private4_enabled ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_action    = "allow"
  rule_number    = var.open_network_acl_ipv4_rule_number

  egress     = false
  cidr_block = "0.0.0.0/0"
  from_port  = 0
  to_port    = 0
  protocol   = "-1"
}

resource "aws_network_acl_rule" "private4_egress" {
  count = local.private_open_network_acl_enabled && local.private4_enabled ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_action    = "allow"
  rule_number    = var.open_network_acl_ipv4_rule_number

  egress     = true
  cidr_block = "0.0.0.0/0"
  from_port  = 0
  to_port    = 0
  protocol   = "-1"
}

resource "aws_network_acl_rule" "private6_ingress" {
  count = local.private_open_network_acl_enabled && local.private6_enabled ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_action    = "allow"
  rule_number    = var.open_network_acl_ipv6_rule_number

  egress          = false
  ipv6_cidr_block = "::/0"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
}

resource "aws_network_acl_rule" "private6_egress" {
  count = local.private_open_network_acl_enabled && local.private6_enabled ? 1 : 0

  network_acl_id = aws_network_acl.private[0].id
  rule_action    = "allow"
  rule_number    = var.open_network_acl_ipv6_rule_number

  egress          = true
  ipv6_cidr_block = "::/0"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule
resource "aws_network_acl_rule" "private_rules" {
  for_each = { for k, v in var.private_network_acl_rules : k => v if local.private_open_network_acl_enabled }

  network_acl_id = aws_network_acl.private[0].id
  rule_action    = each.value.rule_action
  rule_number    = each.value.rule_number

  egress          = lookup(each.value, "egress", false)
  cidr_block      = lookup(each.value, "cidr_block", null)
  ipv6_cidr_block = lookup(each.value, "ipv6_cidr_block", null)
  from_port       = lookup(each.value, "from_port", null)
  to_port         = lookup(each.value, "to_port", null)
  protocol        = each.value.protocol
  icmp_type       = lookup(each.value, "icmp_type", null)
  icmp_code       = lookup(each.value, "icmp_code", null)
}
