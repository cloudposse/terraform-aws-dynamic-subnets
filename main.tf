terraform {
  required_version = "~> 0.9.1"
}

provider "aws" {
  region = "${var.region}"
}

# Get object aws_vpc by vpc_id
data "aws_vpc" "default" {
  id = "${var.vpc_id}"
}

# Get all subnets from the VPC
data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}
