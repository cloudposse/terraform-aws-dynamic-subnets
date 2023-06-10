
locals {
  custom_public_nacls_enabled = local.enabled && !var.default_nacls_enabled && length(module.subnets.public_subnet_ids) > 0
}

resource "aws_network_acl" "custom_public" {
  count = local.custom_public_nacls_enabled ? 1 : 0

  vpc_id = module.vpc.vpc_id
  #bridgecrew:skip=BC_AWS_NETWORKING_50:Ensure NACLs are attached to subnets, because we have.
  subnet_ids = module.subnets.public_subnet_ids

  tags = module.this.tags
}

# See https://www.cisecurity.org/insights/white-papers/security-primer-remote-desktop-protocol
resource "aws_network_acl_rule" "custom_public_ingress_deny_rdp" {
  count = local.custom_public_nacls_enabled ? 1 : 0

  network_acl_id = one(aws_network_acl.custom_public[*].id)
  rule_action    = "deny"
  rule_number    = 10

  egress     = false
  cidr_block = "0.0.0.0/0"
  from_port  = 3389
  to_port    = 3389
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_public_ingress_80" {
  count = local.custom_public_nacls_enabled ? 1 : 0

  network_acl_id = one(aws_network_acl.custom_public[*].id)
  rule_action    = "allow"
  rule_number    = 20

  egress     = false
  cidr_block = "0.0.0.0/0"
  from_port  = 80
  to_port    = 80
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_public_ingress_443" {
  count = local.custom_public_nacls_enabled ? 1 : 0

  network_acl_id = one(aws_network_acl.custom_public[*].id)
  rule_action    = "allow"
  rule_number    = 40

  egress     = false
  cidr_block = "0.0.0.0/0"
  from_port  = 443
  to_port    = 443
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_public_ingress_ephemeral" {
  count = local.custom_public_nacls_enabled ? 1 : 0

  #bridgecrew:skip=BC_AWS_NETWORKING_72:Ensure AWS NACL does not allow ingress from 0.0.0.0/0 to port 3389, because we have denied it above.
  network_acl_id = one(aws_network_acl.custom_public[*].id)
  rule_action    = "allow"
  rule_number    = 60

  egress     = false
  cidr_block = "0.0.0.0/0"
  from_port  = 1024
  to_port    = 65535
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_public_egress_443" {
  count = local.custom_public_nacls_enabled ? 1 : 0

  network_acl_id = one(aws_network_acl.custom_public[*].id)
  rule_action    = "allow"
  rule_number    = 120

  egress     = true
  cidr_block = "0.0.0.0/0"
  from_port  = 443
  to_port    = 443
  protocol   = "tcp"
}

resource "aws_network_acl_rule" "custom_public_egress_ephemeral" {
  count = local.custom_public_nacls_enabled ? 1 : 0

  network_acl_id = one(aws_network_acl.custom_public[*].id)
  rule_action    = "allow"
  rule_number    = 140

  egress     = true
  cidr_block = "0.0.0.0/0"
  from_port  = 1024
  to_port    = 65535
  protocol   = "tcp"
}
