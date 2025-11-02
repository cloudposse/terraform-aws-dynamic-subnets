variable "region" {
  type        = string
  description = "AWS Region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "private_subnets_per_az_count" {
  type        = number
  description = "Number of private subnets per availability zone"
  default     = 3
}

variable "private_subnets_per_az_names" {
  type        = list(string)
  description = "Names for private subnets"
  default     = ["database", "app1", "app2"]
}

variable "public_subnets_per_az_count" {
  type        = number
  description = "Number of public subnets per availability zone"
  default     = 2
}

variable "public_subnets_per_az_names" {
  type        = list(string)
  description = "Names for public subnets"
  default     = ["loadbalancer", "web"]
}

variable "nat_gateway_public_subnet_indices" {
  type        = list(number)
  description = "Indices of public subnets where NAT Gateways should be placed (alternative to nat_gateway_public_subnet_names)"
  default     = [0]
}

variable "nat_gateway_public_subnet_names" {
  type        = list(string)
  description = "Names of public subnets where NAT Gateways should be placed"
  default     = ["loadbalancer"]
  nullable    = true
}
