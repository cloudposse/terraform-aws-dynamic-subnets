variable "namespace" {
  type        = "string"
  description = "Namespace (e.g. `cp` or `cloudposse`)"
}

variable "stage" {
  type        = "string"
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}

variable "name" {
  type        = "string"
  description = "Name (e.g. `app`)"
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `namespace`, `stage`, `name`, and `attributes`"
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `policy` or `role`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. map(`Cluster`,`XYZ`)"
}

variable "subnet_type_tag_key" {
  default     = "cpco.io/subnet/type"
  description = "Key for subnet type tag to provide information about the type of subnets, e.g. `cpco.io/subnet/type=private` or `cpco.io/subnet/type=public`"
}

variable "subnet_type_tag_value_format" {
  default     = "%s"
  description = "This is using the format interpolation symbols to allow the value of the subnet_type_tag_key to be modified."
  type        = "string"
}

variable "region" {
  type        = "string"
  description = "AWS Region (e.g. `us-east-1`)"
}

variable "max_subnet_count" {
  default     = "-1"
  description = "The maximum number of subnets to deploy. 0 for none, -1 to match the number of az's in the region, or a specific number"
}

locals {
  max_subnets_map = {
    "-1" = "${length(data.aws_availability_zones.available.names)}"
    "0"  = "0"
    "1"  = "${var.max_subnet_count}"
  }

  max_subnet_count = "${local.max_subnets_map[signum(var.max_subnet_count)]}"
}

variable "public_subnet_count" {
  default     = -1
  description = "Sets the amount of public subnets to deploy.  -1 will deploy a subnet for every availablility zone within the region, 0 will deploy no subnets. The AZ's supplied will be cycled through to create the subnets"
}

locals {
  public_subnets_map = {
    "-1" = "${length(data.aws_availability_zones.available.names)}"
    "0"  = "0"
    "1"  = "${var.public_subnet_count}"
  }

  ## Keep the subnets within the max_subnets_count limit
  public_subnet_count = "${min(local.public_subnets_map[signum(var.public_subnet_count)], local.max_subnet_count)}"
}

variable "private_subnet_count" {
  default     = -1
  description = "Sets the amount of private subnets to deploy.  -1 will deploy a subnet for every availablility zone within the region, 0 will deploy no subnets. The AZ's supplied will be cycled through to create the subnets"
}

locals {
  private_subnets_map = {
    "-1" = "${length(data.aws_availability_zones.available.names)}"
    "0"  = "0"
    "1"  = "${var.private_subnet_count}"
  }

  ## Keep the subnets within the max_subnets_count limit
  private_subnet_count = "${min(local.private_subnets_map[signum(var.private_subnet_count)], local.max_subnet_count)}"
}

variable "vpc_id" {
  type        = "string"
  description = "VPC ID where subnets will be created (e.g. `vpc-aceb2723`)"
}

variable "igw_id" {
  type        = "string"
  description = "Internet Gateway ID the public route table will point to (e.g. `igw-9c26a123`)"
}

variable "cidr_block" {
  type        = "string"
  description = "Base CIDR block which will be divided into subnet CIDR blocks (e.g. `10.0.0.0/16`), or pass in the vpc_id to use the CIDR from the VPC"
  default     = ""
}

variable "availability_zones" {
  type        = "list"
  description = "List of Availability Zones where subnets will be created. When none provided, all availability zones will be used up to the number provided in the max_public_subnet_count and/or max_private_subnet_count"
  default     = []
}

locals {
  ## If the variable availability_zones is empty, use the list provided by data.aws_availability_zones.available.names
  ## Otherwise use the zones listed in availability_zones
  az_name_map = {
    "0" = ["${data.aws_availability_zones.available.names}"]
    "1" = ["${var.availability_zones}"]
  }

  availability_zones = "${local.az_name_map[signum(length(var.availability_zones))]}"

  ## This selects one of the lists based on the signum() interpolation
  az_map = {
    "-1" = ["${data.aws_availability_zones.available.names}"]
    "1"  = ["${local.availability_zones}"]
    "0"  = []
  }

  ## Select the az from the list using a function like `local.availability_zones_public[count.index % length(local.availability_zones_public)]`
  availability_zones_public  = "${local.az_map[signum(local.public_subnet_count)]}"
  availability_zones_private = "${local.az_map[signum(local.private_subnet_count)]}"
}

variable "vpc_default_route_table_id" {
  default     = ""
  description = "Default route table for public subnets. If not set, will be created. (e.g. `rtb-f4f0ce12`)"
}

variable "public_network_acl_id" {
  default     = ""
  description = "Network ACL ID that will be added to public subnets. If empty, a new ACL will be created"
}

variable "private_network_acl_id" {
  description = "Network ACL ID that will be added to private subnets. If empty, a new ACL will be created"
  default     = ""
}

variable "nat_gateway_enabled" {
  description = "Flag to enable/disable NAT Gateways to allow servers in the private subnets to access the Internet"
  default     = "true"
}

variable "nat_instance_enabled" {
  description = "Flag to enable/disable NAT Instances to allow servers in the private subnets to access the Internet"
  default     = "false"
}

variable "nat_instance_type" {
  description = "NAT Instance type"
  default     = "t3.micro"
}

variable "map_public_ip_on_launch" {
  default     = "true"
  description = "Instances launched into a public subnet should be assigned a public IP address"
}
