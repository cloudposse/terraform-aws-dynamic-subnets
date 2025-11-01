region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]

namespace = "eg"

stage = "test"

name = "separate-public-private-subnets"

# 3 private subnets per AZ
private_subnets_per_az_count = 3
private_subnets_per_az_names = ["database", "app1", "app2"]

# 2 public subnets per AZ
public_subnets_per_az_count = 2
public_subnets_per_az_names = ["loadbalancer", "web"]

# Place NAT Gateway in the "loadbalancer" subnet
nat_gateway_public_subnet_names = ["loadbalancer"]
