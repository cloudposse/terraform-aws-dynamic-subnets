provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "2.0.0"

  ipv4_primary_cidr_block                   = var.ipv4_primary_cidr_block
  assign_generated_ipv6_cidr_block          = true
  ipv6_egress_only_internet_gateway_enabled = true

  context = module.this.context
}

module "subnets" {
  source = "../../"

  availability_zones      = var.availability_zones
  vpc_id                  = module.vpc.vpc_id
  igw_id                  = [module.vpc.igw_id]
  ipv4_enabled            = true
  ipv6_enabled            = true
  ipv6_egress_only_igw_id = [module.vpc.ipv6_egress_only_igw_id]
  ipv4_cidr_block         = [module.vpc.vpc_cidr_block]
  ipv6_cidr_block         = [module.vpc.vpc_ipv6_cidr_block]
  nat_gateway_enabled     = false
  nat_instance_enabled    = false
  route_create_timeout    = "5m"
  route_delete_timeout    = "10m"

  subnet_type_tag_key = "cpco.io/subnet/type"

  private_network_acl_enabled      = var.private_network_acl_enabled
  private_open_network_acl_enabled = var.private_open_network_acl_enabled
  private_network_acl_rules        = var.private_network_acl_rules

  public_network_acl_enabled      = var.public_network_acl_enabled
  public_open_network_acl_enabled = var.public_open_network_acl_enabled
  public_network_acl_rules        = var.public_network_acl_rules

  open_network_acl_ipv4_rule_number = var.open_network_acl_ipv4_rule_number
  open_network_acl_ipv6_rule_number = var.open_network_acl_ipv6_rule_number

  context = module.this.context
}
