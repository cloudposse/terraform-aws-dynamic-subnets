output "public_subnet_cidrs" {
  description = "IPv4 CIDRs assigned to the created public subnets"
  value       = module.subnets.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "IPv4 CIDRs assigned to the created private subnets"
  value       = module.subnets.private_subnet_cidrs
}

output "public_subnet_ipv6_cidrs" {
  description = "IPv6 CIDRs assigned to the created public subnets"
  value       = module.subnets.public_subnet_ipv6_cidrs
}

output "private_subnet_ipv6_cidrs" {
  description = "IPv6 CIDRs assigned to the created private subnets"
  value       = module.subnets.private_subnet_ipv6_cidrs
}

output "vpc_ipv6_cidr" {
  description = "Default IPv6 CIDR of the VPC"
  value       = module.vpc.vpc_ipv6_cidr_block
}

output "public_route_table_ids" {
  description = "IDs of the created public route tables"
  value       = module.subnets.public_route_table_ids
}

output "private_route_table_ids" {
  description = "IDs of the created private route tables"
  value       = module.subnets.private_route_table_ids
}

output "az_private_subnets_map" {
  description = "Map of AZ names to list of private subnet IDs in the AZs"
  value       = module.subnets.az_private_subnets_map
}

output "az_public_subnets_map" {
  description = "Map of AZ names to list of public subnet IDs in the AZs"
  value       = module.subnets.az_public_subnets_map
}

output "az_private_route_table_ids_map" {
  description = "Map of AZ names to list of private route table IDs in the AZs"
  value       = module.subnets.az_private_route_table_ids_map
}

output "az_public_route_table_ids_map" {
  description = "Map of AZ names to list of public route table IDs in the AZs"
  value       = module.subnets.az_public_route_table_ids_map
}

output "named_private_subnets_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of private subnet IDs"
  value       = module.subnets.named_private_subnets_map
}

output "named_public_subnets_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of public subnet IDs"
  value       = module.subnets.named_public_subnets_map
}

output "named_private_route_table_ids_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of private route table IDs"
  value       = module.subnets.named_private_route_table_ids_map
}

output "named_public_route_table_ids_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of public route table IDs"
  value       = module.subnets.named_public_route_table_ids_map
}

output "named_private_subnets_stats_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of objects with each object having three items: AZ, private subnet ID, private route table ID"
  value       = module.subnets.named_private_subnets_stats_map
}

output "named_public_subnets_stats_map" {
  description = "Map of subnet names (specified in `subnets_per_az_names` variable) to lists of objects with each object having three items: AZ, public subnet ID, public route table ID"
  value       = module.subnets.named_public_subnets_stats_map
}
