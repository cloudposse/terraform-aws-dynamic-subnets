output "public_subnet_ids" {
  value = ["${aws_subnet.public.*.id}"]
}

output "private_subnet_ids" {
  value = ["${aws_subnet.private.*.id}"]
}

output "public_subnet_cidrs" {
  value = ["${aws_subnet.public.*.cidr_block}"]
}

output "private_subnet_cidrs" {
  value = ["${aws_subnet.private.*.cidr_block}"]
}

output "public_route_table_ids" {
  value = ["${aws_route_table.public.*.id}"]
}

output "private_route_table_ids" {
  value = ["${aws_route_table.private.*.id}"]
}
