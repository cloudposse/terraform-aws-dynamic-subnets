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
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, etc."
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `policy` or `role`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
}

variable "public_network_acl_id" {
  default = ""
}

variable "private_network_acl_id" {
  default = ""
}

variable "igw_id" {}
