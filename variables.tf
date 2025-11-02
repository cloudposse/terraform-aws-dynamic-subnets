variable "vpc_id" {
  type        = string
  description = "VPC ID where subnets will be created (e.g. `vpc-aceb2723`)"
}

variable "igw_id" {
  type        = list(string)
  description = <<-EOT
    The Internet Gateway ID that the public subnets will route traffic to.
    Used if `public_route_table_enabled` is `true`, ignored otherwise.
    EOT
  default     = []
  nullable    = false
  validation {
    condition     = length(var.igw_id) < 2
    error_message = "Only 1 igw_id can be provided."
  }
}

variable "ipv6_egress_only_igw_id" {
  type        = list(string)
  description = <<-EOT
    The Egress Only Internet Gateway ID the private IPv6 subnets will route traffic to.
    Used if `private_route_table_enabled` is `true` and `ipv6_enabled` is `true`, ignored otherwise.
    EOT
  default     = []
  nullable    = false
  validation {
    condition     = length(var.ipv6_egress_only_igw_id) < 2
    error_message = "Only 1 ipv6_egress_only_igw_id can be provided."
  }
}

variable "max_subnet_count" {
  type        = number
  description = <<-EOT
    Sets the maximum number of each type (public or private) of subnet to deploy.
    `0` will reserve a CIDR for every Availability Zone (excluding Local Zones) in the region, and
    deploy a subnet in each availability zone specified in `availability_zones` or `availability_zone_ids`,
    or every zone if none are specified. We recommend setting this equal to the maximum number of AZs you anticipate using,
    to avoid causing subnets to be destroyed and recreated with smaller IPv4 CIDRs when AWS adds an availability zone.
    Due to Terraform limitations, you can not set `max_subnet_count` from a computed value, you have to set it
    from an explicit constant. For most cases, `3` is a good choice.
    EOT
  default     = 0
  nullable    = false
}

variable "max_nats" {
  type        = number
  description = <<-EOT
    Upper limit on number of NAT Gateways/Instances to create.
    Set to 1 or 2 for cost savings at the expense of availability.
    EOT
  # Default should be MAX_INT, but Terraform does not provide that. 999 is big enough.
  default  = 999
  nullable = false
}

variable "private_subnets_enabled" {
  type        = bool
  description = "If false, do not create private subnets (or NAT gateways or instances)"
  default     = true
  nullable    = false
}

variable "public_subnets_enabled" {
  type        = bool
  description = <<-EOT
    If false, do not create public subnets.
    Since NAT gateways and instances must be created in public subnets, these will also not be created when `false`.
    EOT
  default     = true
  nullable    = false
}

variable "private_label" {
  type        = string
  description = "The string to use in IDs and elsewhere to identify resources for the private subnets and distinguish them from resources for the public subnets"
  default     = "private"
  nullable    = false
}

variable "public_label" {
  type        = string
  description = "The string to use in IDs and elsewhere to identify resources for the public subnets and distinguish them from resources for the private subnets"
  default     = "public"
  nullable    = false
}

variable "ipv4_enabled" {
  type        = bool
  description = "Set `true` to enable IPv4 addresses in the subnets"
  default     = true
  nullable    = false
}

variable "ipv6_enabled" {
  type        = bool
  description = "Set `true` to enable IPv6 addresses in the subnets"
  default     = false
  nullable    = false
}

variable "ipv4_cidr_block" {
  type        = list(string)
  description = <<-EOT
    Base IPv4 CIDR block which will be divided into subnet CIDR blocks (e.g. `10.0.0.0/16`). Ignored if `ipv4_cidrs` is set.
    If no CIDR block is provided, the VPC's default IPv4 CIDR block will be used.
    EOT
  default     = []
  nullable    = false
  validation {
    condition     = length(var.ipv4_cidr_block) < 2
    error_message = "Only 1 ipv4_cidr_block can be provided. Use ipv4_cidrs to provide a CIDR per subnet."
  }
}

variable "ipv6_cidr_block" {
  type        = list(string)
  description = <<-EOT
    Base IPv6 CIDR block from which `/64` subnet CIDRs will be assigned. Must be `/56`. (e.g. `2600:1f16:c52:ab00::/56`).
    Ignored if `ipv6_cidrs` is set. If no CIDR block is provided, the VPC's default IPv6 CIDR block will be used.
    EOT
  default     = []
  nullable    = false
  validation {
    condition     = length(var.ipv6_cidr_block) < 2
    error_message = "Only 1 ipv6_cidr_block can be provided. Use ipv6_cidrs to provide a CIDR per subnet."
  }
}

variable "ipv4_cidrs" {
  type = list(object({
    private = list(string)
    public  = list(string)
  }))
  description = <<-EOT
    Lists of CIDRs to assign to subnets. Order of CIDRs in the lists must not change over time.
    Lists may contain more CIDRs than needed.
    EOT
  default     = []
  nullable    = false
  validation {
    condition     = length(var.ipv4_cidrs) < 2
    error_message = "Only 1 ipv4_cidrs object can be provided. Lists of CIDRs are passed via the `public` and `private` attributes of the single object."
  }
}

variable "ipv6_cidrs" {
  type = list(object({
    private = list(string)
    public  = list(string)
  }))
  description = <<-EOT
    Lists of CIDRs to assign to subnets. Order of CIDRs in the lists must not change over time.
    Lists may contain more CIDRs than needed.
    EOT
  default     = []
  nullable    = false
  validation {
    condition     = length(var.ipv6_cidrs) < 2
    error_message = "Only 1 ipv6_cidrs object can be provided. Lists of CIDRs are passed via the `public` and `private` attributes of the single object."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = <<-EOT
    List of Availability Zones (AZs) where subnets will be created. Ignored when `availability_zone_ids` is set.
    The order of zones in the list ***must be stable*** or else Terraform will continually make changes.
    If no AZs are specified, then `max_subnet_count` AZs will be selected in alphabetical order.
    If `max_subnet_count > 0` and `length(var.availability_zones) > max_subnet_count`, the list
    will be truncated. We recommend setting `availability_zones` and `max_subnet_count` explicitly as constant
    (not computed) values for predictability, consistency, and stability.
    EOT
  default     = []
  nullable    = false
}

variable "availability_zone_ids" {
  type        = list(string)
  description = <<-EOT
    List of Availability Zones IDs where subnets will be created. Overrides `availability_zones`.
    Useful in some regions when using only some AZs and you want to use the same ones across multiple accounts.
    EOT
  default     = []
  nullable    = false
}

variable "availability_zone_attribute_style" {
  type        = string
  description = <<-EOT
    The style of Availability Zone code to use in tags and names. One of `full`, `short`, or `fixed`.
    When using `availability_zone_ids`, IDs will first be translated into AZ names.
    EOT
  default     = "short"
  nullable    = false
}

variable "nat_gateway_enabled" {
  type        = bool
  description = <<-EOT
    Set `true` to create NAT Gateways to perform IPv4 NAT and NAT64 as needed.
    Defaults to `true` unless `nat_instance_enabled` is `true`.
    EOT
  default     = null
}

variable "nat_instance_enabled" {
  type        = bool
  description = <<-EOT
    Set `true` to create NAT Instances to perform IPv4 NAT.
    Defaults to `false`.
    EOT
  default     = null
}

variable "nat_elastic_ips" {
  type        = list(string)
  description = "Existing Elastic IPs (not EIP IDs) to attach to the NAT Gateway(s) or Instance(s) instead of creating new ones."
  default     = []
  nullable    = false
}

variable "nat_gateway_public_subnet_indices" {
  type        = list(number)
  description = <<-EOT
    The index (starting from 0) of the public subnet in each AZ to place the NAT Gateway.
    If you have multiple public subnets per AZ (via `public_subnets_per_az_count`), this determines which one gets the NAT Gateway.
    Default: `[0]` (use the first public subnet in each AZ).
    You can specify multiple indices if you want redundant NATs within an AZ, but this is rarely needed and increases cost.
    Cannot be used together with `nat_gateway_public_subnet_names`.
    Example: `[0]` creates 1 NAT per AZ in the first public subnet.
    Example: `[0, 1]` creates 2 NATs per AZ in the first and second public subnets (expensive).
    EOT
  default     = [0]
  nullable    = false
  validation {
    condition     = length(var.nat_gateway_public_subnet_indices) > 0
    error_message = "The `nat_gateway_public_subnet_indices` must contain at least one index."
  }
}

variable "nat_gateway_public_subnet_names" {
  type        = list(string)
  description = <<-EOT
    The names of the public subnets in each AZ where NAT Gateways should be placed.
    Uses the names from `public_subnets_per_az_names` to determine placement.
    This is more intuitive than using indices - specify the subnet by name instead of position.
    Cannot be used together with `nat_gateway_public_subnet_indices` (only use indices OR names, not both).
    If not specified, defaults to using `nat_gateway_public_subnet_indices`.
    Example: `["loadbalancer"]` creates 1 NAT per AZ in the "loadbalancer" subnet.
    Example: `["loadbalancer", "web"]` creates 2 NATs per AZ in "loadbalancer" and "web" subnets (expensive).
    EOT
  default     = null
  nullable    = true
}

variable "map_public_ip_on_launch" {
  type        = bool
  description = "If `true`, instances launched into a public subnet will be assigned a public IPv4 address"
  default     = true
  nullable    = false
}

variable "private_assign_ipv6_address_on_creation" {
  type        = bool
  description = "If `true`, network interfaces created in a private subnet will be assigned an IPv6 address"
  default     = true
  nullable    = false
}

variable "public_assign_ipv6_address_on_creation" {
  type        = bool
  description = "If `true`, network interfaces created in a public subnet will be assigned an IPv6 address"
  default     = true
  nullable    = false
}

variable "private_dns64_nat64_enabled" {
  type        = bool
  description = <<-EOT
    If `true` and IPv6 is enabled, DNS queries made to the Amazon-provided DNS Resolver in private subnets will return synthetic
    IPv6 addresses for IPv4-only destinations, and these addresses will be routed to the NAT Gateway.
    Requires `public_subnets_enabled`, `nat_gateway_enabled`, and `private_route_table_enabled` to be `true` to be fully operational.
    Defaults to `true` unless there is no public IPv4 subnet for egress, in which case it defaults to `false`.
    EOT
  default     = null
}

variable "public_dns64_nat64_enabled" {
  type        = bool
  description = <<-EOT
    If `true` and IPv6 is enabled, DNS queries made to the Amazon-provided DNS Resolver in public subnets will return synthetic
    IPv6 addresses for IPv4-only destinations, and these addresses will be routed to the NAT Gateway.
    Requires `nat_gateway_enabled` and `public_route_table_enabled` to be `true` to be fully operational.
    EOT
  default     = false
  nullable    = false
}

variable "ipv4_private_instance_hostname_type" {
  type        = string
  description = <<-EOT
    How to generate the DNS name for the instances in the private subnets.
    Either `ip-name` to generate it from the IPv4 address, or
    `resource-name` to generate it from the instance ID.
    EOT
  default     = "ip-name"
  nullable    = false
}

variable "ipv4_private_instance_hostnames_enabled" {
  type        = bool
  description = "If `true`, DNS queries for instance hostnames in the private subnets will be answered with A (IPv4) records."
  default     = false
  nullable    = false
}

variable "ipv6_private_instance_hostnames_enabled" {
  type        = bool
  description = <<-EOT
    If `true` (or if `ipv4_enabled` is `false`), DNS queries for instance hostnames in the private subnets will be answered with AAAA (IPv6) records.
    EOT
  default     = false
  nullable    = false
}

variable "ipv4_public_instance_hostname_type" {
  type        = string
  description = <<-EOT
    How to generate the DNS name for the instances in the public subnets.
    Either `ip-name` to generate it from the IPv4 address, or
    `resource-name` to generate it from the instance ID.
    EOT
  default     = "ip-name"
  nullable    = false
}

variable "ipv4_public_instance_hostnames_enabled" {
  type        = bool
  description = "If `true`, DNS queries for instance hostnames in the public subnets will be answered with A (IPv4) records."
  default     = false
  nullable    = false
}

variable "ipv6_public_instance_hostnames_enabled" {
  type        = bool
  description = <<-EOT
    If `true` (or if `ipv4_enabled` is false), DNS queries for instance hostnames in the public subnets will be answered with AAAA (IPv6) records.
    EOT
  default     = false
  nullable    = false
}

variable "private_open_network_acl_enabled" {
  type        = bool
  description = <<-EOT
    If `true`, a single network ACL be created and it will be associated with every private subnet, and a rule (number 100)
    will be created allowing all ingress and all egress. You can add additional rules to this network ACL
    using the `aws_network_acl_rule` resource.
    If `false`, you will need to manage the network ACL outside of this module.
    EOT
  default     = true
  nullable    = false
}

variable "public_open_network_acl_enabled" {
  type        = bool
  description = <<-EOT
    If `true`, a single network ACL be created and it will be associated with every public subnet, and a rule
    will be created allowing all ingress and all egress. You can add additional rules to this network ACL
    using the `aws_network_acl_rule` resource.
    If `false`, you will need to manage the network ACL outside of this module.
    EOT
  default     = true
  nullable    = false
}

variable "open_network_acl_ipv4_rule_number" {
  type        = number
  description = "The `rule_no` assigned to the network ACL rules for IPv4 traffic generated by this module"
  default     = 100
  nullable    = false
}

variable "open_network_acl_ipv6_rule_number" {
  type        = number
  description = "The `rule_no` assigned to the network ACL rules for IPv6 traffic generated by this module"
  default     = 111
  nullable    = false
}

variable "private_route_table_enabled" {
  type        = bool
  description = <<-EOT
    If `true`, a network route table and default route to the NAT gateway, NAT instance, or egress-only gateway
    will be created for each private subnet (1:1). If false, you will need to create your own route table(s) and route(s).
    EOT
  default     = true
  nullable    = false
}

variable "public_route_table_ids" {
  type        = list(string)
  description = <<-EOT
    List optionally containing the ID of a single route table shared by all public subnets
    or exactly one route table ID for each public subnet.
    If provided, it overrides `public_route_table_per_subnet_enabled`.
    If omitted and `public_route_table_enabled` is `true`,
    one or more network route tables will be created for the public subnets,
    according to the setting of `public_route_table_per_subnet_enabled`.
    EOT
  default     = []
  nullable    = false
}

variable "public_route_table_enabled" {
  type        = bool
  description = <<-EOT
    If `true`, network route table(s) will be created as determined by `public_route_table_per_subnet_enabled` and
    appropriate routes will be added to destinations this module knows about.
    If `false`, you will need to create your own route table(s) and route(s).
    Ignored if `public_route_table_ids` is non-empty.
    EOT
  default     = true
  nullable    = false
}

variable "public_route_table_per_subnet_enabled" {
  type        = bool
  description = <<-EOT
    If `true` (and `public_route_table_enabled` is `true`), a separate network route table will be created for and associated with each public subnet.
    If `false` (and `public_route_table_enabled` is `true`), a single network route table will be created and it will be associated with every public subnet.
    If not set, it will be set to the value of `public_dns64_nat64_enabled`.
    EOT
  default     = null
}

variable "route_create_timeout" {
  type        = string
  description = "Time to wait for a network routing table entry to be created, specified as a Go Duration, e.g. `2m`. Use `null` for proivder default."
  default     = null
}
locals { route_create_timeout = var.aws_route_create_timeout == null ? var.route_create_timeout : var.aws_route_create_timeout }

variable "route_delete_timeout" {
  type        = string
  description = "Time to wait for a network routing table entry to be deleted, specified as a Go Duration, e.g. `2m`. Use `null` for proivder default."
  default     = null
}
locals { route_delete_timeout = var.aws_route_delete_timeout == null ? var.route_delete_timeout : var.aws_route_delete_timeout }

variable "subnet_create_timeout" {
  type        = string
  description = "Time to wait for a subnet to be created, specified as a Go Duration, e.g. `2m`. Use `null` for proivder default."
  # 10m is the AWS Provider's default value
  default = null
}

variable "subnet_delete_timeout" {
  type        = string
  description = "Time to wait for a subnet to be deleted, specified as a Go Duration, e.g. `5m`. Use `null` for proivder default."
  # 20m is the AWS Provider's default value
  default = null
}

variable "private_subnets_additional_tags" {
  type        = map(string)
  description = "Additional tags to be added to private subnets"
  default     = {}
  nullable    = false
}

variable "public_subnets_additional_tags" {
  type        = map(string)
  description = "Additional tags to be added to public subnets"
  default     = {}
  nullable    = false
}

variable "subnets_per_az_count" {
  type        = number
  description = <<-EOT
    The number of subnet of each type (public or private) to provision per Availability Zone.
    EOT
  default     = 1
  nullable    = false
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
  nullable    = false
}

variable "public_subnets_per_az_count" {
  type        = number
  description = <<-EOT
    The number of public subnets to provision per Availability Zone.
    If not provided, defaults to the value of `subnets_per_az_count` for backward compatibility.
    Set this to create a different number of public subnets than private subnets.
    EOT
  default     = null
  validation {
    condition     = var.public_subnets_per_az_count == null || var.public_subnets_per_az_count > 0
    error_message = "The `public_subnets_per_az_count` value must be greater than 0 or null."
  }
}

variable "public_subnets_per_az_names" {
  type        = list(string)
  description = <<-EOT
    The names to assign to the public subnets per Availability Zone.
    If not provided, defaults to the value of `subnets_per_az_names` for backward compatibility.
    If provided, the length must match `public_subnets_per_az_count`.
    The names will be used as keys in the outputs `named_public_subnets_map` and `named_public_route_table_ids_map`.
    EOT
  default     = null
  nullable    = true
}

variable "private_subnets_per_az_count" {
  type        = number
  description = <<-EOT
    The number of private subnets to provision per Availability Zone.
    If not provided, defaults to the value of `subnets_per_az_count` for backward compatibility.
    Set this to create a different number of private subnets than public subnets.
    EOT
  default     = null
  validation {
    condition     = var.private_subnets_per_az_count == null || var.private_subnets_per_az_count > 0
    error_message = "The `private_subnets_per_az_count` value must be greater than 0 or null."
  }
}

variable "private_subnets_per_az_names" {
  type        = list(string)
  description = <<-EOT
    The names to assign to the private subnets per Availability Zone.
    If not provided, defaults to the value of `subnets_per_az_names` for backward compatibility.
    If provided, the length must match `private_subnets_per_az_count`.
    The names will be used as keys in the outputs `named_private_subnets_map` and `named_private_route_table_ids_map`.
    EOT
  default     = null
  nullable    = true
}

#############################################################
############## NAT instance configuration ###################
variable "nat_instance_type" {
  type        = string
  description = "NAT Instance type"
  default     = "t3.micro"
  nullable    = false
}

variable "nat_instance_ami_id" {
  type        = list(string)
  description = <<-EOT
    A list optionally containing the ID of the AMI to use for the NAT instance.
    If the list is empty (the default), the latest official AWS NAT instance AMI
    will be used. NOTE: The Official NAT instance AMI is being phased out and
    does not support NAT64. Use of a NAT gateway is recommended instead.
    EOT
  default     = []
  nullable    = false
  validation {
    condition     = length(var.nat_instance_ami_id) < 2
    error_message = "Only 1 NAT Instance AMI ID can be provided."
  }
}

variable "nat_instance_cpu_credits_override" {
  type        = string
  description = <<-EOT
    NAT Instance credit option for CPU usage. Valid values are "standard" or "unlimited".
    T3 and later instances are launched as unlimited by default. T2 instances are launched as standard by default.
    EOT
  default     = ""
  nullable    = false
  validation {
    condition = contains(["standard", "unlimited", ""], var.nat_instance_cpu_credits_override)
    # Validation error messages must be on a single line, among other restrictions.
    # See https://github.com/hashicorp/terraform/issues/24123
    error_message = "The `nat_instance_cpu_credits_override` value must be either \"standard\", \"unlimited\", or empty string."
  }
}

variable "metadata_http_endpoint_enabled" {
  type        = bool
  description = "Whether the metadata service is available on the created NAT instances"
  default     = true
  nullable    = false
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  description = "The desired HTTP PUT response hop limit (between 1 and 64) for instance metadata requests on the created NAT instances"
  default     = 1
  nullable    = false
}

variable "metadata_http_tokens_required" {
  type        = bool
  description = "Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2, on the created NAT instances"
  default     = true
  nullable    = false
}

variable "nat_instance_root_block_device_encrypted" {
  type        = bool
  description = "Whether to encrypt the root block device on the created NAT instances"
  default     = true
  nullable    = false
}
locals { nat_instance_root_block_device_encrypted = var.root_block_device_encrypted == null ? var.nat_instance_root_block_device_encrypted : var.root_block_device_encrypted }

############## END of NAT instance configuration ########################
############## Please add new variables above this section ##############
