output "private_subnet_ids" {
  description = "IDs of the created private subnets"
  value       = module.subnets.private_subnet_ids
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the created private subnets"
  value       = module.subnets.private_subnet_cidrs
}

output "public_subnet_ids" {
  description = "IDs of the created public subnets"
  value       = module.subnets.public_subnet_ids
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the created public subnets"
  value       = module.subnets.public_subnet_cidrs
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = module.subnets.nat_gateway_ids
}

output "nat_ips" {
  description = "Elastic IP addresses of NAT gateways"
  value       = module.subnets.nat_ips
}

output "az_private_subnets_map" {
  description = "Map of AZ names to list of private subnet IDs in that AZ"
  value       = module.subnets.az_private_subnets_map
}

output "az_public_subnets_map" {
  description = "Map of AZ names to list of public subnet IDs in that AZ"
  value       = module.subnets.az_public_subnets_map
}

output "private_route_table_ids" {
  description = "IDs of the created private route tables"
  value       = module.subnets.private_route_table_ids
}

output "public_route_table_ids" {
  description = "IDs of the created public route tables"
  value       = module.subnets.public_route_table_ids
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}

output "max_nats_configured" {
  description = "The max_nats value configured for this deployment"
  value       = var.max_nats
}
