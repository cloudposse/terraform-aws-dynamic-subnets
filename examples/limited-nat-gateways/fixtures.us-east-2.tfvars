region = "us-east-2"

namespace = "eg"

stage = "test"

name = "limited-nat"

# Use 3 AZs
# max_nats is controlled by the test via Vars parameter
# Default is 1 (from variables.tf), but tests override as needed
availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
