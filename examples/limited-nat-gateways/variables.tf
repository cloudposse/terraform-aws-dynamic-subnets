variable "region" {
  type        = string
  description = "AWS region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "max_nats" {
  type        = number
  description = "Maximum number of NAT Gateways to create (limits NATs to fewer than number of AZs for cost savings)"
  default     = 1
}
