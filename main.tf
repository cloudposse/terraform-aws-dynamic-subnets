# Get object aws_vpc by vpc_id
data "aws_vpc" "default" {
  count = var.enabled ? 1 : 0
  id    = var.vpc_id
}

data "aws_availability_zones" "available" {
  count = var.enabled ? 1 : 0
}

locals {
  availability_zones_count = var.enabled ? length(var.availability_zones) : 0
  enabled                  = var.enabled ? 1 : 0
}

data "aws_eip" "nat_ips" {
  count     = var.enabled ? length(var.existing_nat_ips) : 0
  public_ip = element(var.existing_nat_ips, count.index)
}

locals {
  use_existing_eips = length(var.existing_nat_ips) > 0
}

module "label" {
  source              = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  attributes          = var.attributes
  namespace           = var.namespace
  environment         = var.environment
  stage               = var.stage
  delimiter           = var.delimiter
  name                = var.name
  tags                = var.tags
  additional_tag_map  = var.additional_tag_map
  regex_replace_chars = var.regex_replace_chars
  label_order         = var.label_order
  context             = var.context
  enabled             = var.enabled
}
