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
