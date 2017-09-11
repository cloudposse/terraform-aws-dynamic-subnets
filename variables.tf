variable "region" {
  default = ""
}

variable "namespace" {
  default = ""
}

variable "stage" {
  default = ""
}

variable "name" {
  default = ""
}

variable "vpc_id" {
  default = ""
}

variable "cidr_block" {
  default = ""
}

variable "availability_zones" {
  type = "list"
}

variable "vpc_default_route_table_id" {
  default = ""
}

variable "create_network_acl" {
  default = false
}

variable "depends_on" {
  type = "list"
  default = []
}
