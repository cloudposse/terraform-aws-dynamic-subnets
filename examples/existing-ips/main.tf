provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "2.0.0"

  ipv4_primary_cidr_block          = "172.16.0.0/16"
  assign_generated_ipv6_cidr_block = false # disable IPv6

  context = module.this.context
}

resource "aws_eip" "nat_ips" {
  count = length(var.availability_zones)

  vpc = true

  depends_on = [
    module.vpc
  ]
}

module "subnets" {
  source = "../../"

  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  ipv4_cidr_block      = [module.vpc.vpc_cidr_block]
  nat_elastic_ips      = aws_eip.nat_ips.*.public_ip
  nat_gateway_enabled  = true
  nat_instance_enabled = false

  subnets_per_az_count = var.subnets_per_az_count
  subnets_per_az_names = var.subnets_per_az_names

  context = module.this.context
}
