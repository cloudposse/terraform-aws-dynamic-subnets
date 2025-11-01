output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "availability_zones" {
  description = "List of Availability Zones where subnets were created"
  value       = module.subnets.availability_zones
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.subnets.private_subnet_ids
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  value       = module.subnets.private_subnet_cidrs
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.subnets.public_subnet_ids
}

output "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  value       = module.subnets.public_subnet_cidrs
}

output "named_private_subnets_map" {
  description = "Map of private subnet names to subnet IDs"
  value       = module.subnets.named_private_subnets_map
}

output "named_public_subnets_map" {
  description = "Map of public subnet names to subnet IDs"
  value       = module.subnets.named_public_subnets_map
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.subnets.nat_gateway_ids
}

output "nat_ips" {
  description = "Elastic IP Addresses in use by NAT"
  value       = module.subnets.nat_ips
}

output "private_route_table_ids" {
  description = "Private route table IDs"
  value       = module.subnets.private_route_table_ids
}

output "public_route_table_ids" {
  description = "Public route table IDs"
  value       = module.subnets.public_route_table_ids
}
