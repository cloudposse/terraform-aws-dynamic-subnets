provider "aws" {
  region = var.region
}

locals {
  enabled = module.this.enabled
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "2.0.0"

  ipv4_primary_cidr_block                   = "172.16.0.0/16"
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
  nat_gateway_enabled     = true
  nat_instance_enabled    = false
  route_create_timeout    = "5m"
  route_delete_timeout    = "10m"

  public_subnets_additional_tags  = { format("%s/subnet/type", module.this.id) = "public" }
  private_subnets_additional_tags = { format("%s/subnet/type", module.this.id) = "private" }

  subnets_per_az_count = var.subnets_per_az_count
  subnets_per_az_names = var.subnets_per_az_names

  private_open_network_acl_enabled = var.default_nacls_enabled
  public_open_network_acl_enabled  = var.default_nacls_enabled

  context = module.this.context
}
