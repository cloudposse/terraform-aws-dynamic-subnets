terraform {
  required_version = "~> 0.10.2"
}

provider "aws" {
  region = "${var.region}"
}

# Get object aws_vpc by vpc_id
data "aws_vpc" "default" {
  id = "${var.vpc_id}"
}

data "aws_availability_zones" "available" {}

resource "null_resource" "depends_on" {
  triggers = {
    depends_on = "${join(" ", var.depends_on)}"
  }
}

# Get the Internet Gateway attached to the VPC
# https://www.terraform.io/docs/providers/aws/d/internet_gateway.html
# https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInternetGateways.html
data "aws_internet_gateway" "default" {
    depends_on = ["null_resource.depends_on"]
  filter {
    name   = "attachment.vpc-id"
    values = ["${var.vpc_id}"]
  }
}
