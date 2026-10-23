output "private_subnet_ids" {
  description = "IDs of the created private subnets"
  value       = module.subnets.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways created"
  value       = module.subnets.nat_gateway_ids
}

output "nat_gateway_route_table_id" {
  description = "ID of the automatically created route table for Regional NAT Gateway"
  value       = module.subnets.nat_gateway_route_table_id
}

output "nat_gateway_regional_addresses" {
  description = "Information about IP addresses and network interfaces for Regional NAT Gateway"
  value       = module.subnets.nat_gateway_regional_addresses
}

output "availability_zones" {
  description = "List of Availability Zones where subnets were created"
  value       = module.subnets.availability_zones
}
