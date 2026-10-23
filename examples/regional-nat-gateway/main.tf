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

  availability_zones              = var.availability_zones
  vpc_id                          = module.vpc.vpc_id
  igw_id                          = [module.vpc.igw_id]
  ipv4_cidr_block                 = [module.vpc.vpc_cidr_block]
  nat_gateway_enabled             = true
  nat_gateway_availability_mode   = "regional"
  public_subnets_enabled          = false # Regional NAT doesn't require public subnets
  private_subnets_enabled         = true
  max_subnet_count                = 3

  context = module.this.context
}
