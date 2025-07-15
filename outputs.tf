output "availability_zones" {
  description = "List of Availability Zones where subnets were created"
  value       = local.vpc_availability_zones
}

output "availability_zone_ids" {
  description = "List of Availability Zones IDs where subnets were created, when available"
  value = local.use_az_ids ? var.availability_zone_ids : [
    for az in local.vpc_availability_zones : local.az_name_map[az]
  ]
}

output "public_subnet_ids" {
  description = "IDs of the created public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "ARNs of the created public subnets"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_ids" {
  description = "IDs of the created private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "ARNs of the created private subnets"
  value       = aws_subnet.private[*].arn
}

# Provide some consistency in CIDR outputs by always returning a list.
# Avoid (or at least reduce) `count` problems by toggling the return
# value via configuration rather than computing it via `compact()`.
output "public_subnet_cidrs" {
  description = "IPv4 CIDR blocks of the created public subnets"
  value       = local.public4_enabled ? aws_subnet.public[*].cidr_block : []
}

output "public_subnet_ipv6_cidrs" {
  description = "IPv6 CIDR blocks of the created public subnets"
  value       = local.public6_enabled ? aws_subnet.public[*].ipv6_cidr_block : []
}

output "private_subnet_cidrs" {
  description = "IPv4 CIDR blocks of the created private subnets"
  value       = local.private4_enabled ? aws_subnet.private[*].cidr_block : []
}

output "private_subnet_ipv6_cidrs" {
  description = "IPv6 CIDR blocks of the created private subnets"
  value       = local.private6_enabled ? aws_subnet.private[*].ipv6_cidr_block : []
}

output "public_route_table_ids" {
  description = "IDs of the created public route tables"
  value       = aws_route_table.public[*].id
}

output "private_route_table_ids" {
  description = "IDs of the created private route tables"
  value       = aws_route_table.private[*].id
}

output "public_network_acl_id" {
  description = "ID of the Network ACL created for public subnets"
  value       = local.public_open_network_acl_enabled ? aws_network_acl.public[0].id : null
}

output "private_network_acl_id" {
  description = "ID of the Network ACL created for private subnets"
  value       = local.private_open_network_acl_enabled ? aws_network_acl.private[0].id : null
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways created"
  value       = aws_nat_gateway.default[*].id
}

output "nat_instance_ids" {
  description = "IDs of the NAT Instances created"
  value       = aws_instance.nat_instance[*].id
}

output "nat_instance_ami_id" {
  description = "ID of AMI used by NAT instance"
  value       = local.nat_instance_enabled ? local.nat_instance_ami_id : null
}

output "nat_ips" {
  description = "Elastic IP Addresses in use by NAT"
  value       = local.need_nat_eip_data ? var.nat_elastic_ips : aws_eip.default[*].public_ip
}

output "nat_eip_allocation_ids" {
  description = "Elastic IP allocations in use by NAT"
  value       = local.nat_eip_allocations
}

output "az_private_subnets_map" {
  description = "Map of AZ names to list of private subnet IDs in the AZs"
  value       = local.az_private_subnets_map
}

output "az_public_subnets_map" {
  description = "Map of AZ names to list of public subnet IDs in the AZs"
  value       = local.az_public_subnets_map
}

output "az_private_route_table_ids_map" {
  description = "Map of AZ names to list of private route table IDs in the AZs"
  value       = local.az_private_route_table_ids_map
}

output "az_public_route_table_ids_map" {
  description = "Map of AZ names to list of public route table IDs in the AZs"
  value       = local.az_public_route_table_ids_map
}

output "named_private_subnets_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of private subnet IDs"
  value       = local.named_private_subnets_map
}

output "named_public_subnets_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of public subnet IDs"
  value       = local.named_public_subnets_map
}

output "named_private_route_table_ids_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of private route table IDs"
  value       = local.named_private_route_table_ids_map
}

output "named_public_route_table_ids_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of public route table IDs"
  value       = local.named_public_route_table_ids_map
}

output "named_private_subnets_stats_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of objects with each object having these items: AZ, private subnet ID, private route table ID, NAT Gateway ID"
  value       = local.named_private_subnets_stats_map
}

output "named_public_subnets_stats_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of objects with each object having these items: AZ, public subnet ID, public route table ID, NAT Gateway ID"
  value       = local.named_public_subnets_stats_map
}

output "az_nat_gateway_ids_map" {
  description = "Map of AZ names to list of NAT Gateway IDs in the AZs"
  value       = local.az_nat_gateway_ids_map
}
