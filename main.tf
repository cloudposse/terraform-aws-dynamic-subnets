terraform {
  required_version = ">= 0.10.2"
}

provider "aws" {
  region = "${var.region}"
}

# Get object aws_vpc by vpc_id
data "aws_vpc" "default" {
  id = "${var.vpc_id}"
}

data "aws_availability_zones" "available" {}
