output "existing_ips" {
  value = aws_eip.nat_ips.*.public_ip
}

output "nat_ips" {
  value = module.subnets.nat_ips
}