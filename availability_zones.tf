data "aws_availability_zones" "available" {}

locals {
  ## If the variable availability_zones is empty, use the list provided by data.aws_availability_zones.available.names
  ## Otherwise use the zones listed in availability_zones
  az_name_map = {
    "0" = ["${data.aws_availability_zones.available.names}"]
    "1" = ["${var.availability_zones}"]
  }

  availability_zones = "${local.az_name_map[signum(length(var.availability_zones))]}"

  ## This selects one of the lists based on the signum() interpolation
  az_map = {
    "-1" = ["${data.aws_availability_zones.available.names}"]
    "1"  = ["${local.availability_zones}"]
    "0"  = []
  }

  ## Select the az from the list using a function like `local.availability_zones_public[count.index % length(local.availability_zones_public)]`
  availability_zones_public  = "${local.az_map[signum(local.public_subnet_count)]}"
  availability_zones_private = "${local.az_map[signum(local.private_subnet_count)]}"
}

## This should be depreciated in the future.
locals {
  max_subnets_map = {
    "-1" = "${length(local.availability_zones)}"
    "0"  = "0"
    "1"  = "${var.max_subnet_count}"
  }

  max_subnet_count = "${local.max_subnets_map[signum(var.max_subnet_count)]}"
}
