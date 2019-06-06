output "public_subnet_ids" {
  description = "IDs of the created public subnets"
  value       = ["${aws_subnet.public.*.id}"]
}

output "private_subnet_ids" {
  description = "IDs of the created private subnets"
  value       = ["${aws_subnet.private.*.id}"]
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the created public subnets"
  value       = ["${aws_subnet.public.*.cidr_block}"]
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the created private subnets"
  value       = ["${aws_subnet.private.*.cidr_block}"]
}

output "public_route_table_ids" {
  description = "IDs of the created public route tables"
  value       = ["${aws_route_table.public.*.id}"]
}

output "private_route_table_ids" {
  description = "IDs of the created private route tables"
  value       = ["${aws_route_table.private.*.id}"]
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways created"
  value       = ["${aws_nat_gateway.default.*.id}"]
}

output "nat_instance_ids" {
  description = "IDs of the NAT Instances created"
  value       = ["${aws_instance.nat_instance.*.id}"]
}

output "availability_zones" {
  description = "List of Availability Zones where subnets were created"
  value       = "${distinct(compact(concat(local.availability_zones_public,local.availability_zones_private)))}"
}

output "availability_zones_public" {
  description = "List of public Availability Zones where subnets were created"
  value       = "${distinct(compact(local.availability_zones_public))}"
}

output "availability_zones_private" {
  description = "List of private Availability Zones where subnets were created"
  value       = "${distinct(compact(local.availability_zones_private))}"
}