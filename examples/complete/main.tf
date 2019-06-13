module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.3.4"
  namespace  = "${local.namespace}"
  stage      = "${local.stage}"
  name       = "${local.name}"
  cidr_block = "172.16.0.0/16"
}

module "subnets" {
  source              = "../../"
  region              = "${local.region}"
  availability_zones  = "${local.availability_zones}"
  namespace           = "${local.namespace}"
  stage               = "${local.stage}"
  name                = "${local.name}"
  region              = "${local.region}"
  vpc_id              = "${module.vpc.vpc_id}"
  igw_id              = "${module.vpc.igw_id}"
  cidr_block          = "${module.vpc.vpc_cidr_block}"
  nat_gateway_enabled = "true"
}
