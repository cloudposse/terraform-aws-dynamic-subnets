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
