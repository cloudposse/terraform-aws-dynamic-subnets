output "nat_gateway_public_ips" {
  description = "DEPRECATED: use `nat_ips` instead. Public IPv4 IP addresses in use by NAT."
  value       = local.need_nat_eip_data ? var.nat_elastic_ips : aws_eip.default.*.public_ip
}

