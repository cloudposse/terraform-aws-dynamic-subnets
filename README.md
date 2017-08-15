# tf_subnets

## Module Usage

### Argument Reference

Note: this module is intended for use with existing VPC and existing
Internet Gateway.
You should use [tf_vpc](https://github.com/cloudposse/tf_vpc) module if
you plan to use new (separate) VPC.

* `availability_zones`: (Required) List of AZ.
* `name`: (Required) Name of these resources
* `region`: (Required) AWS region. Used to find remote state.
* `stage`: (Required) Stage associated with these resources
* `namespace`: (Required) Namespace associated with these resources
* `vpc_id`: (Required) AWS Virtual Private Cloud ID.
* `igw_id`: (Required) AWS Internet Gateway for public subnets. Only one igw can be attached to a VPC.
* `vpc_default_route_table_id`: A default route table for public subnets. Provides access to Internet. If not set here - will be created.

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
  vpc_default_route_table_id = "${var.vpc_default_route_table_id}"
}
```
