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
  default     = 0
  description = "Sets the maximum amount of subnets to deploy.  0 will deploy a subnet for every provided availablility zone (in `availability_zones` variable) within the region"
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
  description = "Base CIDR block which will be divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)"
}

variable "availability_zones" {
  type        = "list"
  description = "List of Availability Zones where subnets will be created"
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
