region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "eg"

stage = "test"

name = "custom-nacl-rules"

# Create a Network ACL for the private subnets
private_network_acl_enabled = true

# Don't create all ingress and all egress for the private subnets
private_open_network_acl_enabled = false

# Create custom NACL rules for the private subnets
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule
private_network_acl_rules = {}

# Create a Network ACL for the public subnets
public_network_acl_enabled = true

# Don't create all ingress and all egress for the public subnets
public_open_network_acl_enabled = false

# Create custom NACL rules for the public subnets
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule
public_network_acl_rules = {}
