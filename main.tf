terraform {
  required_version = "~> 0.9.1"
}

provider "aws" {
  region = "${var.region}"
}

module "tf_label" {
  source    = "git::https://github.com/cloudposse/tf_label.git?ref=tags/0.1.0"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.name}"
}

# Get object aws_vpc by vpc_id
data "aws_vpc" "default" {
  id = "${var.vpc_id}"
}

# Get all subnets from the necessary vpc
data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}
