# Pin the `aws` provider
# https://www.terraform.io/docs/configuration/providers.html
# Any non-beta version >= 2.12.0 and < 2.13.0, e.g. 2.12.X
provider "aws" {
  version = "~> 2.12.0"
  region  = "${var.region}"
}

# Terraform
#--------------------------------------------------------------
terraform {
  required_version = "~> 0.11.0"
}

# Get object aws_vpc by vpc_id
data "aws_vpc" "default" {
  id = "${var.vpc_id}"
}
