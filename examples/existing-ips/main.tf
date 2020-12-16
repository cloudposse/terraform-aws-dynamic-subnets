provider "aws" {
  region = var.region
}

module "vpc" {
  source     = "cloudposse/vpc/aws"
  version    = "0.8.1"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  cidr_block = "172.16.0.0/16"
}

module "subnets" {
  source               = "../../"
  availability_zones   = var.availability_zones
  namespace            = var.namespace
  stage                = var.stage
  name                 = var.name
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  existing_nat_ips     = var.existing_nat_ips
  nat_gateway_enabled  = true
  nat_instance_enabled = false
}
