module "public_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = [var.public_label]
  tags = merge(
    var.public_subnets_additional_tags,
    var.subnet_type_tag_key != null && var.subnet_type_tag_value_format != null ? { (var.subnet_type_tag_key) = format(var.subnet_type_tag_value_format, var.public_label) } : {}
  )

  context = module.this.context
}

resource "aws_subnet" "public" {
  count = local.public_enabled ? local.subnet_az_count : 0

  vpc_id            = local.vpc_id
  availability_zone = local.subnet_availability_zones[count.index]

  # When provisioning both public and private subnets, the public subnets get the second set of CIDRs.
  # Use element()'s wrap-around behavior to handle the case where we are only provisioning public subnets.
  cidr_block      = local.public4_enabled ? element(local.ipv4_public_subnet_cidrs, count.index) : null
  ipv6_cidr_block = local.public6_enabled ? element(local.ipv6_public_subnet_cidrs, count.index) : null
  ipv6_native     = local.public6_enabled && !local.public4_enabled

  #bridgecrew:skip=BC_AWS_NETWORKING_53:Public VPCs should be allowed to default to public IPs
  map_public_ip_on_launch = local.public4_enabled ? var.map_public_ip_on_launch : null

  assign_ipv6_address_on_creation = local.public6_enabled ? var.public_assign_ipv6_address_on_creation : null
  enable_dns64                    = local.public6_enabled ? local.public_dns64_enabled : null

  enable_resource_name_dns_a_record_on_launch    = local.public4_enabled ? var.ipv4_public_instance_hostnames_enabled : null
  enable_resource_name_dns_aaaa_record_on_launch = local.public6_enabled ? var.ipv6_public_instance_hostnames_enabled || !local.public4_enabled : null

  private_dns_hostname_type_on_launch = local.public4_enabled ? var.ipv4_public_instance_hostname_type : null


  tags = merge(
    module.public_label.tags,
    {
      "Name" = format("%s%s%s", module.public_label.id, local.delimiter, local.subnet_az_abbreviations[count.index])
    }
  )

  lifecycle {
    ignore_changes = [tags.kubernetes, tags.SubnetType]
  }

  timeouts {
    create = var.subnet_create_timeout
    delete = var.subnet_delete_timeout
  }
}

resource "aws_route_table" "public" {
  # May need 1 table or 1 per AZ
  count = local.create_public_route_tables ? local.public_route_table_count : 0

  vpc_id = local.vpc_id

  tags = module.public_label.tags
}

resource "aws_route" "public" {
  count = local.public4_enabled && local.igw_configured ? local.public_route_table_count : 0

  route_table_id         = local.public_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id[0]

  timeouts {
    create = var.aws_route_create_timeout
    delete = var.aws_route_delete_timeout
  }
}

resource "aws_route" "public6" {
  count = local.public6_enabled && local.igw_configured ? local.public_route_table_count : 0

  route_table_id              = local.public_route_table_ids[count.index]
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = var.igw_id[0]

  timeouts {
    create = var.aws_route_create_timeout
    delete = var.aws_route_delete_timeout
  }
}

resource "aws_route_table_association" "public" {
  count = local.public_route_table_enabled ? local.subnet_az_count : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = element(local.public_route_table_ids, count.index)
}

resource "aws_network_acl" "public" {
  count = local.public_open_network_acl_enabled ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.public.*.id

  tags = module.public_label.tags
}

resource "aws_network_acl_rule" "public4_ingress" {
  count = local.public_open_network_acl_enabled && local.public4_enabled ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_action    = "allow"
  rule_number    = var.open_network_acl_ipv4_rule_number

  egress     = false
  cidr_block = "0.0.0.0/0"
  from_port  = 0
  to_port    = 0
  #checkov:skip=CKV_AWS_229:Ensure no NACL allow ingress from 0.0.0.0:0 to port 21
  #checkov:skip=CKV_AWS_230:Ensure no NACL allow ingress from 0.0.0.0:0 to port 20
  #checkov:skip=CKV_AWS_231:Ensure no NACL allow ingress from 0.0.0.0:0 to port 3389
  #checkov:skip=CKV_AWS_232:Ensure no NACL allow ingress from 0.0.0.0:0 to port 22
  protocol = "-1"
}

resource "aws_network_acl_rule" "public4_egress" {
  count = local.public_open_network_acl_enabled && local.public4_enabled ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_action    = "allow"
  rule_number    = var.open_network_acl_ipv4_rule_number

  egress     = true
  cidr_block = "0.0.0.0/0"
  from_port  = 0
  to_port    = 0
  protocol   = "-1"
}

resource "aws_network_acl_rule" "public6_ingress" {
  count = local.public_open_network_acl_enabled && local.public6_enabled ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_action    = "allow"
  rule_number    = var.open_network_acl_ipv6_rule_number

  egress          = false
  ipv6_cidr_block = "::/0"
  from_port       = 0
  to_port         = 0
  #checkov:skip=CKV_AWS_229:Ensure no NACL allow ingress from 0.0.0.0:0 to port 21
  #checkov:skip=CKV_AWS_230:Ensure no NACL allow ingress from 0.0.0.0:0 to port 20
  #checkov:skip=CKV_AWS_231:Ensure no NACL allow ingress from 0.0.0.0:0 to port 3389
  #checkov:skip=CKV_AWS_232:Ensure no NACL allow ingress from 0.0.0.0:0 to port 22
  protocol = "-1"
}

resource "aws_network_acl_rule" "public6_egress" {
  count = local.public_open_network_acl_enabled && local.public6_enabled ? 1 : 0

  network_acl_id = aws_network_acl.public[0].id
  rule_action    = "allow"
  rule_number    = var.open_network_acl_ipv6_rule_number

  egress          = true
  ipv6_cidr_block = "::/0"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
}
