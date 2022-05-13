output "existing_ips" {
  description = "IP Addresses created by this module for use by NAT"
  value       = aws_eip.nat_ips.*.public_ip
}

output "nat_ips" {
  description = "IP Addresses in use by NAT"
  value       = module.subnets.nat_ips
}
