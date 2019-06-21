variable "subnet_type_tag_key" {
  default     = "cpco.io/subnet/type"
  description = "Key for subnet type tag to provide information about the type of subnets, e.g. `cpco.io/subnet/type=private` or `cpco.io/subnet/type=public`"
}

variable "subnet_type_tag_value_format" {
  default     = "%s"
  description = "This is using the format interpolation symbols to allow the value of the subnet_type_tag_key to be modified."
  type        = "string"
}

variable "max_subnet_count" {
  ## This variable is converted into a calcuated local value in availability_zones.tf
  default     = "-1"
  description = "The maximum number of subnets to deploy. 0 for none, -1 to match the number of az's in the region, or a specific number"
}

variable "public_subnet_count" {
  ## This variable is converted into a calcuated local value in public.tf
  default     = -1
  description = "Sets the amount of public subnets to deploy.  -1 will deploy a subnet for every availablility zone within the region, 0 will deploy no subnets. The AZ's supplied will be cycled through to create the subnets"
}

variable "private_subnet_count" {
  ## This variable is converted into a calcuated local value in private.tf
  default     = -1
  description = "Sets the amount of private subnets to deploy.  -1 will deploy a subnet for every availablility zone within the region, 0 will deploy no subnets. The AZ's supplied will be cycled through to create the subnets"
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
  ## This variable is converted into a calcuated local value in availability_zones.tf
  type        = "list"
  description = "List of Availability Zones where subnets will be created. When none provided, all availability zones will be used up to the number provided in the public_subnet_count and/or private_subnet_count, and then will be reused if the number of subnets requested is more than the number of availability zones"
  default     = []
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

variable "region" {
  type        = "string"
  description = "The region to pass to the AWS provider nested in this module."
}
