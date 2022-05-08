provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "1.1.0"

  cidr_block = "172.16.0.0/16"

  assign_generated_ipv6_cidr_block          = true
  ipv6_egress_only_internet_gateway_enabled = true

  context = module.this.context
}

module "subnets" {
  source = "../../"

  availability_zones       = var.availability_zones
  vpc_id                   = module.vpc.vpc_id
  igw_id                   = [module.vpc.igw_id]
  ipv4_enabled             = true
  ipv6_enabled             = true
  ipv6_egress_only_igw_id  = [module.vpc.ipv6_egress_only_igw_id]
  ipv4_cidr_block          = [module.vpc.vpc_cidr_block]
  ipv6_cidr_block          = [module.vpc.vpc_ipv6_cidr_block]
  nat_gateway_enabled      = false
  nat_instance_enabled     = false
  aws_route_create_timeout = "5m"
  aws_route_delete_timeout = "10m"

  subnet_type_tag_key = "cpco.io/subnet/type"

  context = module.this.context
}
