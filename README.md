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
* `vpc_default_route_table_id`: A default route table for public subnets. Provides access to Internet. If not set here - will be created.

```
module "subnets" {
  source = "git::https://github.com/cloudposse/tf_subnets.git?ref=tags/0.1.6"

  availability_zones         = "${var.availability_zones}"
  namespace                  = "${var.namespace}"
  name                       = "${var.name}"
  stage                      = "${var.stage}"
  region                     = "${var.region}"
  vpc_id                     = "${var.vpc_id}"
  cidr_block                 = "${var.cidr_block}"
  vpc_default_route_table_id = "${var.vpc_default_route_table_id}"
}
```

## Variables

|  Name                        |  Default       |  Description                                                                                                                         | Required |
|:----------------------------:|:--------------:|:------------------------------------------------------------------------------------------------------------------------------------:|:--------:|
| namespace                    | ``             | Namespace (e.g. `cp` or `cloudposse`)                                                                                                | Yes      |
| stage                        | ``             | Stage (e.g. `prod`, `dev`, `staging`)                                                                                                | Yes      |
| name                         | ``             | Name  (e.g. `bastion` or `db`)                                                                                                       | Yes      |
| region                       | ``             | AWS Region where module should operate (e.g. `us-east-1`)                                                                            | Yes      |
| vpc_id                       | ``             | The VPC ID where subnets will be created (e.g. `vpc-aceb2723`)                                                                       | Yes      |
| cidr_block                   | ``             | The base CIDR block which will be divided into subnet CIDR blocks (e.g. `10.0.0.0/16`)                                               | Yes      |
| vpc_default_route_table_id   | ``             | The default route table for public subnets. Provides access to the Internet. If not set here, will be created. (e.g. `rtb-f4f0ce12`) | No       |
| availability_zones           | []             | The list of Availability Zones where subnets will be created (e.g. `["us-eas-1a", "us-eas-1b"]`)                                     | Yes      |
