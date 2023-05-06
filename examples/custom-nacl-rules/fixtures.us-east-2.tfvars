region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "eg"

stage = "test"

name = "custom-nacl-rules"

# VPC CIDR block
ipv4_primary_cidr_block = "172.16.0.0/16"

# Create private subnets
private_subnets_enabled = true

# Create a Network ACL for the private subnets
private_network_acl_enabled = true

# Don't create all ingress and all egress rules for the private subnets
private_open_network_acl_enabled = false

# Create custom NACL rules for the private subnets
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule
private_network_acl_rules = {
  "Allow TCP port 8080 from the same VPC" : {
    rule_action = "allow"
    rule_number = 10
    protocol    = "tcp"
    egress      = false
    cidr_block  = "172.16.0.0/16"
    from_port   = 8080
    to_port     = 8080
  }
  "Allow TCP port 22 from the same VPC" : {
    rule_action = "allow"
    rule_number = 20
    protocol    = "tcp"
    egress      = false
    cidr_block  = "172.16.0.0/16"
    from_port   = 22
    to_port     = 22
  }
}

# Create public subnets
public_subnets_enabled = true

# Create a Network ACL for the public subnets
public_network_acl_enabled = true

# Don't create all ingress and all egress rules for the public subnets
public_open_network_acl_enabled = false

# Create custom NACL rules for the public subnets
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule
public_network_acl_rules = {
  "Allow all IPv4 egress" : {
    rule_action = "allow"
    rule_number = 10
    protocol    = "-1"
    egress      = true
    cidr_block  = "0.0.0.0/0"
    from_port   = 0
    to_port     = 0
  }
  "Allow all IPv6 egress" : {
    rule_action     = "allow"
    rule_number     = 20
    protocol        = "-1"
    egress          = true
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }
  "Allow TCP port 443 IPv4 ingress" : {
    rule_action = "allow"
    rule_number = 30
    protocol    = "tcp"
    egress      = false
    cidr_block  = "0.0.0.0/0"
    from_port   = 443
    to_port     = 443
  }
  "Allow TCP port 443 IPv6 ingress" : {
    rule_action     = "allow"
    rule_number     = 40
    protocol        = "tcp"
    egress          = false
    ipv6_cidr_block = "::/0"
    from_port       = 443
    to_port         = 443
  }
}
