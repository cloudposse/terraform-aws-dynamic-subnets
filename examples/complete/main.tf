provider "aws" {
  region = var.region
}

module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.16.2"
  cidr_block = "172.16.0.0/16"

  # temporary, until VPC module is updated
  namespace = module.this.context.namespace
  stage     = module.this.context.stage
  name      = module.this.context.name
}

module "subnets" {
  source                   = "../../"
  availability_zones       = var.availability_zones
  vpc_id                   = module.vpc.vpc_id
  igw_id                   = module.vpc.igw_id
  cidr_block               = module.vpc.vpc_cidr_block
  nat_gateway_enabled      = false
  nat_instance_enabled     = false
  aws_route_create_timeout = "5m"
  aws_route_delete_timeout = "10m"

  context = module.this.context
}
