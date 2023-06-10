
locals {
  custom_public_nacls_enabled = local.enabled && !var.default_nacls_enabled
}

resource "aws_network_acl" "custom_public" {
  count = local.custom_public_nacls_enabled ? 1 : 0

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.subnets.public_subnet_ids

  tags = module.this.tags
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
