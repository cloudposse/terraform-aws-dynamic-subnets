# We add these variables here (and would add outputs at the end of this file
# if we wanted them) to show how you can add NACLs to an existing root module
# such as https://github.com/cloudposse/terraform-aws-components/tree/main/modules/vpc
# without having to modify any pre-existing files the root module itself.
# This is useful if you want to be able to update the root module in the future
# without having to worry about your changes being overwritten.

variable "vpn_cidr" {
  type        = string
  description = "VPN CIDR block to permit to access the private subnets"
  default     = null
}

variable "alternate_region_cidr" {
  type        = string
  description = "Alternate region CIDR block to permit to access the private subnets"
  default     = null
}

locals {
  custom_private_nacls_enabled = local.enabled && !var.default_nacls_enabled && length(module.subnets.private_subnet_ids) > 0

  private_open_cidrs = concat(
    module.subnets.private_subnet_cidrs,
    var.alternate_region_cidr != null ? [var.alternate_region_cidr] : [],
  )
}

resource "aws_network_acl" "custom_private" {
  count = local.custom_private_nacls_enabled ? 1 : 0

  vpc_id = module.vpc.vpc_id
  #bridgecrew:skip=BC_AWS_NETWORKING_50: Ensure NACLs are attached to subnets, because we have.
  subnet_ids = module.subnets.private_subnet_ids

  tags = module.this.tags
}

# See https://www.cisecurity.org/insights/white-papers/security-primer-remote-desktop-protocol
resource "aws_network_acl_rule" "custom_private_ingress_deny_rdp" {
  count = local.custom_private_nacls_enabled ? 1 : 0

  network_acl_id = one(aws_network_acl.custom_private[*].id)
  rule_action    = "deny"
  rule_number    = 10

  egress     = false
  cidr_block = "0.0.0.0/0"
  from_port  = 3389
  to_port    = 3389
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_private_ingress_80" {
  count = local.custom_private_nacls_enabled ? length(module.subnets.public_subnet_cidrs) : 0

  network_acl_id = one(aws_network_acl.custom_private[*].id)
  rule_action    = "allow"
  rule_number    = 20 + count.index

  egress     = false
  cidr_block = module.subnets.public_subnet_cidrs[count.index]
  from_port  = 80
  to_port    = 80
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_private_ingress_443" {
  count = local.custom_private_nacls_enabled ? length(module.subnets.public_subnet_cidrs) : 0

  network_acl_id = one(aws_network_acl.custom_private[*].id)
  rule_action    = "allow"
  rule_number    = 40 + count.index

  egress     = false
  cidr_block = module.subnets.public_subnet_cidrs[count.index]
  from_port  = 443
  to_port    = 443
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_private_ingress_ephemeral" {
  count = local.custom_private_nacls_enabled ? 1 : 0

  network_acl_id = one(aws_network_acl.custom_private[*].id)
  rule_action    = "allow"
  rule_number    = 60

  egress     = false
  cidr_block = "0.0.0.0/0"
  from_port  = 1024
  to_port    = 65535
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_private_ingress_vpn" {
  count = local.custom_private_nacls_enabled && var.vpn_cidr != null ? 1 : 0

  network_acl_id = one(aws_network_acl.custom_private[*].id)
  rule_action    = "allow"
  rule_number    = 70

  egress     = false
  cidr_block = var.vpn_cidr
  from_port  = 22
  to_port    = 22
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_private_ingress_account" {
  count = local.custom_private_nacls_enabled ? length(local.private_open_cidrs) : 0

  network_acl_id = one(aws_network_acl.custom_private[*].id)
  rule_action    = "allow"
  rule_number    = 80 + count.index

  egress     = false
  cidr_block = local.private_open_cidrs[count.index]
  from_port  = 0
  to_port    = 65535
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_private_egress_443" {
  count = local.custom_private_nacls_enabled ? 1 : 0

  network_acl_id = one(aws_network_acl.custom_private[*].id)
  rule_action    = "allow"
  rule_number    = 120

  egress     = true
  cidr_block = "0.0.0.0/0"
  from_port  = 443
  to_port    = 443
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_private_egress_ephemeral" {
  count = local.custom_private_nacls_enabled ? length(module.subnets.public_subnet_cidrs) : 0

  network_acl_id = one(aws_network_acl.custom_private[*].id)
  rule_action    = "allow"
  rule_number    = 140 + count.index

  egress     = true
  cidr_block = module.subnets.public_subnet_cidrs[count.index]
  from_port  = 1024
  to_port    = 65535
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_private_egress_vpn" {
  count = local.custom_private_nacls_enabled && var.vpn_cidr != null ? 1 : 0

  network_acl_id = one(aws_network_acl.custom_private[*].id)
  rule_action    = "allow"
  rule_number    = 160

  egress     = true
  cidr_block = var.vpn_cidr
  from_port  = 1024
  to_port    = 65535
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_private_egress_account" {
  count = local.custom_private_nacls_enabled ? length(local.private_open_cidrs) : 0

  network_acl_id = one(aws_network_acl.custom_private[*].id)
  rule_action    = "allow"
  rule_number    = 180 + count.index

  egress     = true
  cidr_block = local.private_open_cidrs[count.index]
  from_port  = 0
  to_port    = 65535
  protocol   = "tcp"
}

