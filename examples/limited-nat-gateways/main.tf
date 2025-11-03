provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "3.0.0"

  ipv4_primary_cidr_block = "172.16.0.0/16"

  context = module.this.context
}

module "subnets" {
  source = "../../"

  availability_zones = var.availability_zones
  vpc_id             = module.vpc.vpc_id
  igw_id             = [module.vpc.igw_id]
  ipv4_cidr_block    = [module.vpc.vpc_cidr_block]

  # Test max_nats feature: limit NAT Gateways to fewer than number of AZs
  # This is a cost optimization - only create NATs in some AZs, not all
  # Private subnets in AZs without NATs will route through NATs in other AZs
  max_nats = var.max_nats

  nat_gateway_enabled  = true
  nat_instance_enabled = false

  context = module.this.context
}
