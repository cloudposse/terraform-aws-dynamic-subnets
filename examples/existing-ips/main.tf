provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "0.18.1"

  cidr_block = "172.16.0.0/16"

  context = module.this.context
}

resource "aws_eip" "nat_ips" {
  for_each = toset(var.availability_zones)
  vpc      = true

  depends_on = [
    module.vpc
  ]
}

module "subnets" {
  source = "../../"

  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_elastic_ips      = [for az, eip in aws_eip.nat_ips : eip.public_ip]
  nat_gateway_enabled  = true
  nat_instance_enabled = false

  context = module.this.context
}
