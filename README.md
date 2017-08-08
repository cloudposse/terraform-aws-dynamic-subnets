# tf_subnets

## Module usage

### Argument Reference

* `availability_zones`: (Required) List of AZ.
* `name`: (Required) Name of CloudTrail trail.
* `region`: (Required) AWS region. Used to find remote state.
* `stage`: (Required)
* `namespace`: (Required) Used to find namespace
* `vpc_id`: (Required) AWS Virtual Private Cloud ID.
* `igw_id`: AWS Internet Gateway for public subnets. Only one igw can be attached to a VPC. If not set here - will be created.
* `vpc_default_route_table`: A default route table for public subnets. Provides access to Internet. If not set here - will be created.

```
module "tf_subnets" {
  source = "git::https://github.com/cloudposse/tf_subnets.git?ref=master"

  availability_zones      = "${var.availability_zones}"
  namespace               = "${var.namespace}"
  name                    = "${var.name}"
  stage                   = "${var.stage}"
  region                  = "${var.region}"
  vpc_id                  = "${var.vpc_id}"
  igw_id                  = "${var.igw_id}"
  vpc_default_route_table = "${var.vpc_default_route_table}"
}
```
