output "public_subnet_ids" {
  description = "AWS ID of the created public subnet"
  value       = ["${aws_subnet.public.*.id}"]
}

output "private_subnet_ids" {
  description = "AWS ID of the created private subnet"
  value       = ["${aws_subnet.private.*.id}"]
}

output "public_subnet_cidrs" {
  description = "CIDR of the created public subnet"
  value       = ["${aws_subnet.public.*.cidr_block}"]
}

output "private_subnet_cidrs" {
  description = "CIDR of the created private subnet"
  value       = ["${aws_subnet.private.*.cidr_block}"]
}

output "public_route_table_ids" {
  description = "AWS ID of the created public route table"
  value       = ["${aws_route_table.public.*.id}"]
}

output "private_route_table_ids" {
  description = "AWS ID of the created private route table"
  value       = ["${aws_route_table.private.*.id}"]
}
