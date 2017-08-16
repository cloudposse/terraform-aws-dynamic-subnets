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
module "subnets" {
  source = "git::https://github.com/cloudposse/tf_subnets.git?ref=master"

  availability_zones         = "${var.availability_zones}"
  namespace                  = "${var.namespace}"
  name                       = "${var.name}"
  stage                      = "${var.stage}"
  region                     = "${var.region}"
  vpc_id                     = "${var.vpc_id}"
  igw_id                     = "${var.igw_id}"
  vpc_default_route_table_id = "${var.vpc_default_route_table_id}"
}
```

## Variables

|  Name                        |  Default       |  Description                                              | Required |
|:----------------------------:|:--------------:|:--------------------------------------------------------:|:--------:|
| namespace                    | ``             | Namespace (e.g. `cp` or `cloudposse`)                    | Yes      |
| stage                        | ``             | Stage (e.g. `prod`, `dev`, `staging`)                     | Yes      |
| name                         | ``             | Name  (e.g. `bastion` or `db`)                           | Yes      |
| region                       | ``             | AWS Region where module should operate (e.g. `us-east-1`)| Yes      |
| vpc_id                       | ``             | The VPC ID where subnets will be created (e.g. `vpc-aceb2723`)         | Yes      |
| igw_id                       | ``             | The Internet Gateway ID public route table will point to (e.g. `igw-9c26a123`) | Yes       |
| vpc_default_route_table_id   | ``             | The scheduling expression. (e.g. cron(0 20 * * ? *) or rate(5 minutes) | No       |
| availability_zones           | []             | The scheduling expression. (e.g. cron(0 20 * * ? *) or rate(5 minutes) | Yes       |
