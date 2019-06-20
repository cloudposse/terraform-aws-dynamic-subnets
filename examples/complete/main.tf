//module "vpc" {
//  source = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.4.1"
//
//  providers = {
//    aws = "aws"
//  }
//
//  namespace  = "${var.namespace}"
//  stage      = "${var.stage}"
//  name       = "${var.name}"
//  cidr_block = "172.16.0.0/16"
//}
//
//module "subnets" {
//  source = "../../"
//
//  providers = {
//    aws = "aws"
//  }
//
//  availability_zones   = "${var.availability_zones}"
//  max_subnet_count     = 4
//  public_subnet_count  = 2
//  private_subnet_count = 4
//  namespace            = "${var.namespace}"
//  stage                = "${var.stage}"
//  name                 = "${var.name}"
//  vpc_id               = "${module.vpc.vpc_id}"
//  igw_id               = "${module.vpc.igw_id}"
//  cidr_block           = "${module.vpc.vpc_cidr_block}"
//  nat_gateway_enabled  = "false"
//  nat_instance_enabled = "false"
//
//  # Optionally customize the key for subnet type tag
//  subnet_type_tag_key = "SubnetType"
//
//  # The %s gets replaced with 'public' on public subnets and 'private' on private subnets
//  subnet_type_tag_value_format = "test-%s"
//}


module "vpc" {
  source = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.4.1"

  providers = {
    aws = "aws"
  }

  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  cidr_block = "172.16.0.0/16"
}

module "subnets" {
  source = "../../"

  providers = {
    aws = "aws"
  }

  availability_zones  = "${var.availability_zones}"
  namespace           = "${var.namespace}"
  stage               = "${var.stage}"
  name                = "${var.name}"
  vpc_id              = "${module.vpc.vpc_id}"
  igw_id              = "${module.vpc.igw_id}"
  cidr_block          = "${module.vpc.vpc_cidr_block}"
  nat_gateway_enabled = "true"
}
