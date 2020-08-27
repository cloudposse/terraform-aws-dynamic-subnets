variable "region" {
  type        = string
  description = "AWS region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones where subnets will be created"
}

variable "namespace" {
  type        = string
  description = "Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp'"
}

variable "stage" {
  type        = string
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
}

variable "name" {
  type        = string
  description = "Solution/application name, e.g. 'app' or 'cluster'"
}

variable "existing_nat_ips" {
  type        = list(string)
  default     = []
  description = "Existing Elastic IPs to attach to the NAT Gateway or Instance instead of creating a new one."
}
