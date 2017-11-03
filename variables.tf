variable "region" {}

variable "namespace" {}

variable "stage" {}

variable "name" {}

variable "vpc_id" {}

variable "cidr_block" {}

variable "availability_zones" {
  type = "list"
}

variable "vpc_default_route_table_id" {
  default = ""
}

variable "delimiter" {
  default = "-"
}

variable "attributes" {
  type    = "list"
  default = []
}

variable "tags" {
  type    = "map"
  default = {}
}

variable "public_network_acl_id" {
  default = ""
}

variable "private_network_acl_id" {
  default = ""
}

variable "igw_id" {}

variable "nat_gateway_enabled" {
  description = "Flag to enable/disable NAT gateways"
  default     = "true"
}

variable "additional_routes_public" {
  type    = "list"
  default = []
}

variable "additional_routes_private" {
  type    = "list"
  default = []
}
