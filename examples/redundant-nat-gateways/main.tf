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

  # Create different numbers of public and private subnets
  private_subnets_per_az_count = var.private_subnets_per_az_count
  private_subnets_per_az_names = var.private_subnets_per_az_names

  public_subnets_per_az_count = var.public_subnets_per_az_count
  public_subnets_per_az_names = var.public_subnets_per_az_names

  # Enable NAT Gateway in EACH public subnet for redundancy
  nat_gateway_enabled             = true
  nat_instance_enabled            = false
  nat_gateway_public_subnet_names = var.nat_gateway_public_subnet_names

  context = module.this.context
}
