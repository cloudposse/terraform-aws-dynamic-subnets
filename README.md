# terraform-aws-dynamic-subnets [![Build Status](https://travis-ci.org/cloudposse/terraform-aws-dynamic-subnets.svg?branch=master)](https://travis-ci.org/cloudposse/terraform-aws-dynamic-subnets)

Terraform module to provision public and private [`subnets`](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html) in an existing [`VPC`](https://aws.amazon.com/vpc)

__Note:__ this module is intended for use with an existing VPC and existing Internet Gateway.
To create a new VPC, use [terraform-aws-vpc](https://github.com/cloudposse/terraform-aws-vpc) module.


## Usage

```hcl
module "subnets" {
  source              = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
  namespace           = "cp"
  stage               = "prod"
  name                = "app"
  region              = "us-east-1"
  vpc_id              = "vpc-XXXXXXXX"
  igw_id              = "igw-XXXXXXXX"
  cidr_block          = "10.0.0.0/16"
  availability_zones  = "["us-east-1a", "us-east-1b"]"
}
```


## Variables

|  Name                        |  Default    |  Description                                                                                        | Required |
|:-----------------------------|:-----------:|:----------------------------------------------------------------------------------------------------|:--------:|
| namespace                    | ``          | Namespace (_e.g._ `cp` or `cloudposse`)                                                             | Yes      |
| stage                        | ``          | Stage (_e.g._ `prod`, `dev`, `staging`)                                                             | Yes      |
| name                         | ``          | Name (_e.g._ `app`)                                                                                 | Yes      |
| region                       | ``          | AWS Region (_e.g._ `us-east-1`)                                                                     | Yes      |
| vpc_id                       | ``          | VPC ID where subnets will be created (_e.g._ `vpc-aceb2723`)                                        | Yes      |
| igw_id                       | ``          | Internet Gateway ID the public route table will point to (_e.g._ `igw-9c26a123`)                    | Yes      |
| cidr_block                   | ``          | Base CIDR block which will be divided into subnet CIDR blocks (_e.g._ `10.0.0.0/16`)                | Yes      |
| availability_zones           | `[]`        | List of Availability Zones where subnets will be created (_e.g._ `["us-east-1a", "us-east-1b"]`)    | Yes      |
| attributes                   | `[]`        | Additional attributes (_e.g._ `policy` or `role`)                                                   | No       |
| tags                         | `{}`        | Additional tags  (_e.g._ `map("Cluster","xyz")`                                                     | No       |
| delimiter                    | `-`         | Delimiter to be used between `namespace`, `stage`, `name`, and `attributes`                         | No       |
| vpc_default_route_table_id   | ``          | Default route table for public subnets. If not set, will be created (_e.g._ `rtb-f4f0ce12`)         | No       |
| public_network_acl_id        | ``          | Network ACL ID that will be added to public subnets. If empty, a new ACL will be created            | No       |
| private_network_acl_id       | ``          | Network ACL ID that will be added to private subnets. If empty, a new ACL will be created           | No       |
| nat_gateway_enabled          | `true`      | Flag to enable/disable NAT gateways for private subnets                                             | No       |


## Outputs

| Name                       | Description                       |
|:---------------------------|:----------------------------------|
| public_subnet_ids          | List of public subnet IDs         |
| private_subnet_ids         | List of private subnet IDs        |
| public_route_table_ids     | List of public route table IDs    |
| private_route_table_ids    | List of private route table IDs   |


## Subnet calculation logic

`terraform-aws-dynamic-subnets` creates a set of subnets based on `${var.cidr_block}` input and number of Availability Zones in the region.

For subnet set calculation, the module uses Terraform interpolation

[cidrsubnet](https://www.terraform.io/docs/configuration/interpolation.html#cidrsubnet-iprange-newbits-netnum-).


```hcl
${
  cidrsubnet(
  signum(length(var.cidr_block)) == 1 ?
  var.cidr_block : data.aws_vpc.default.cidr_block,
  ceil(log(length(data.aws_availability_zones.available.names) * 2, 2)),
  count.index)
}
```


1. Use `${var.cidr_block}` input (if specified) or
   use a VPC CIDR block `data.aws_vpc.default.cidr_block` (e.g. `10.0.0.0/16`)
2. Get number of available AZ in the region (e.g. `length(data.aws_availability_zones.available.names)`)
3. Calculate `newbits`. `newbits` number specifies how many subnets
   be the CIDR block (input or VPC) will be divided into. `newbits` is the number of `binary digits`.

    Example:

    `newbits = 1` - 2 subnets are available (`1 binary digit` allows to count up to `2`)

    `newbits = 2` - 4 subnets are available (`2 binary digits` allows to count up to `4`)

    `newbits = 3` - 8 subnets are available (`3 binary digits` allows to count up to `8`)

    etc.

    1. We know, that we have `6` AZs in a `us-east-1` region (see step 2).
    2. We need to create `1 public` subnet and `1 private` subnet in each AZ,
       thus we need to create `12 subnets` in total (`6` AZs * (`1 public` + `1 private`)).
    3. We need `4 binary digits` for that ( 2<sup>4</sup> = 16 ).
       In order to calculate the number of `binary digits` we should use `logarithm`
       function. We should use `base 2` logarithm because decimal numbers
       can be calculated as `powers` of binary number.
       See [Wiki](https://en.wikipedia.org/wiki/Binary_number#Decimal)
       for more details

       Example:

       For `12 subnets` we need `3.58` `binary digits` (log<sub>2</sub>12)

       For `16 subnets` we need `4` `binary digits` (log<sub>2</sub>16)

       For `7 subnets` we need `2.81` `binary digits` (log<sub>2</sub>7)

       etc.

    4. We can't use fractional values to calculate the number of `binary digits`.
       We can't round it down because smaller number of `binary digits` is
       insufficient to represent the required subnets.
       We round it up. See [ceil](https://www.terraform.io/docs/configuration/interpolation.html#ceil-float-).

       Example:

       For `12 subnets` we need `4` `binary digits` (ceil(log<sub>2</sub>12))

       For `16 subnets` we need `4` `binary digits` (ceil(log<sub>2</sub>16))

       For `7 subnets` we need `3` `binary digits` (ceil(log<sub>2</sub>7))

       etc.

    5. Assign private subnets according to AZ number (we're using `count.index` for that).
    6. Assign public subnets according to AZ number but with a shift according to the number of AZs in the region (see step 2)


## Help

**Got a question?**

File a GitHub [issue](https://github.com/cloudposse/terraform-aws-dynamic-subnets/issues), send us an [email](mailto:hello@cloudposse.com) or reach out to us on [Gitter](https://gitter.im/cloudposse/).


## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/cloudposse/terraform-aws-dynamic-subnets/issues) to report any bugs or file feature requests.

### Developing

If you are interested in being a contributor and want to get involved in developing `terraform-aws-dynamic-subnets`, we would love to hear from you! Shoot us an [email](mailto:hello@cloudposse.com).

In general, PRs are welcome. We follow the typical "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull request** so that we can review your changes

**NOTE:** Be sure to merge the latest from "upstream" before making a pull request!


## License

[APACHE 2.0](LICENSE) © 2018 [Cloud Posse, LLC](https://cloudposse.com)

See [LICENSE](LICENSE) for full details.

    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.


## About

`terraform-aws-dynamic-subnets` is maintained and funded by [Cloud Posse, LLC][website].

![Cloud Posse](https://cloudposse.com/logo-300x69.png)


Like it? Please let us know at <hello@cloudposse.com>

We love [Open Source Software](https://github.com/cloudposse/)!

See [our other projects][community]
or [hire us][hire] to help build your next cloud platform.

  [website]: https://cloudposse.com/
  [community]: https://github.com/cloudposse/
  [hire]: https://cloudposse.com/contact/


## Contributors

| [![Erik Osterman][erik_img]][erik_web]<br/>[Erik Osterman][erik_web] | [![Andriy Knysh][andriy_img]][andriy_web]<br/>[Andriy Knysh][andriy_web] |[![Igor Rodionov][igor_img]][igor_web]<br/>[Igor Rodionov][igor_img]
|-------------------------------------------------------|------------------------------------------------------------------|------------------------------------------------------------------|

[erik_img]: http://s.gravatar.com/avatar/88c480d4f73b813904e00a5695a454cb?s=144
[erik_web]: https://github.com/osterman/
[andriy_img]: https://avatars0.githubusercontent.com/u/7356997?v=4&u=ed9ce1c9151d552d985bdf5546772e14ef7ab617&s=144
[andriy_web]: https://github.com/aknysh/
[igor_img]: http://s.gravatar.com/avatar/bc70834d32ed4517568a1feb0b9be7e2?s=144
[igor_web]: https://github.com/goruha/
