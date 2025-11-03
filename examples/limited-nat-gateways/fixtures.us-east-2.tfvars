region = "us-east-2"

namespace = "eg"

stage = "test"

name = "limited-nat"

# Use 3 AZs but only create 1 NAT Gateway (in first AZ)
# This tests the max_nats feature and the bug fix for route table mapping
availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]

max_nats = 1
