terraform {
  required_version = "~> 0.12.0"
}

# Pin the `aws` provider
# https://www.terraform.io/docs/configuration/providers.html
# Any non-beta version >= 2.12.0 and < 2.13.0, e.g. 2.12.X
provider "aws" {
  version = ">= 2.12.0"
  region  = var.region
}