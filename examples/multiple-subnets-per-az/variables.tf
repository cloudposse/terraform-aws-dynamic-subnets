variable "region" {
  type        = string
  description = "AWS region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones where subnets will be created"
}

variable "subnets_per_az_count" {
  type        = number
  description = <<-EOT
    The number of subnet of each type (public or private) to provision per Availability Zone.
    EOT
  default     = 1

  validation {
    condition = var.subnets_per_az_count > 0
    # Validation error messages must be on a single line, among other restrictions.
    # See https://github.com/hashicorp/terraform/issues/24123
    error_message = "The `subnets_per_az` value must be greater than 0."
  }
}

variable "subnets_per_az_names" {
  type = list(string)

  description = <<-EOT
    The subnet names of each type (public or private) to provision per Availability Zone.
    This variable is optional.
    If a list of names is provided, the list items will be used as keys in the outputs `named_private_subnets_map`, `named_public_subnets_map`,
    `named_private_route_table_ids_map` and `named_public_route_table_ids_map`
    EOT
  default     = ["common"]
}
