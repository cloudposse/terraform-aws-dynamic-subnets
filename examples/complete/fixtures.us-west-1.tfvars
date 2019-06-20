region = "us-west-1"

# Don't use `us-west-1b`
# Value (us-west-1b) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-west-1c, us-west-1a
availability_zones = ["us-west-1a", "us-west-1c"]

namespace = "eg"

name = "vpc"

stage = "test"
