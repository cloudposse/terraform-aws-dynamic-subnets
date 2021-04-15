output "public_subnet_ids" {
  description = "IDs of the created public subnets"
  value       = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  description = "IDs of the created private subnets"
  value       = aws_subnet.private.*.id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the created public subnets"
  value       = aws_subnet.public.*.cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the created private subnets"
  value       = aws_subnet.private.*.cidr_block
}

output "public_route_table_ids" {
  description = "IDs of the created public route tables"
  value       = aws_route_table.public.*.id
}

output "private_route_table_ids" {
  description = "IDs of the created private route tables"
  value       = aws_route_table.private.*.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways created"
  value       = aws_nat_gateway.default.*.id
}

output "nat_gateway_public_ips" {
  description = "EIP of the NAT Gateway"
  value       = aws_eip.default.*.public_ip
}

output "nat_instance_ids" {
  description = "IDs of the NAT Instances created"
  value       = aws_instance.nat_instance.*.id
}

output "availability_zones" {
  description = "List of Availability Zones where subnets were created"
  value       = var.availability_zones
}

output "nat_ips" {
  description = "IP Addresses in use for NAT"
  value       = coalescelist(aws_eip.default.*.public_ip, aws_eip.nat_instance.*.public_ip, data.aws_eip.nat_ips.*.public_ip, [""])
}
