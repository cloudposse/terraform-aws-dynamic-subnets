## Subnet calculation logic

`terraform-aws-dynamic-subnets` creates a set of subnets based on various CIDR inputs and 
the maximum possible number of subnets, which is `max_subnet_count` when specified or
the number of Availability Zones in the region when `max_subnet_count` is left at 
its default value of zero.

You can explicitly provide CIDRs for subnets via `ipv4_cidrs` and `ipv6_cidrs` inputs if you want,
but the usual use case is to provide a single CIDR which this module will subdivide into a set
of CIDRs as follows:

1. Get number of available AZ in the region:
```
existing_az_count = length(data.aws_availability_zones.available.names)
```
2. Determine how many sets of subnets are being created. (Usually it is `2`: `public` and `private`): `subnet_type_count`.
3. Multiply the results of (1) and (2) to determine how many CIDRs to reserve:
```
cidr_count = existing_az_count * subnet_type_count
```

4. Calculate the number of bits needed to enumerate all the CIDRs:
```
subnet_bits = ceil(log(cidr_count, 2))
```
5. Reserve CIDRs for private subnets using [`cidrsubnet`](https://www.terraform.io/language/functions/cidrsubnet): 
```
private_subnet_cidrs = [ for netnumber in range(0, existing_az_count): cidrsubnet(cidr_block, subnet_bits, netnumber) ]
```
6. Reserve CIDRs for public subnets in the second half of the CIDR block:
```
public_subnet_cidrs = [ for netnumber in range(existing_az_count, existing_az_count * 2): cidrsubnet(cidr_block, subnet_bits, netnumber) ]
```


Note that this means that, for example, in a region with 4 availability zones, if you specify only 3 availability zones 
in `var.availability_zones`, this module will still reserve CIDRs for the 4th zone. This is so that if you later
want to expand into that zone, the existing subnet CIDR assignments will not be disturbed. If you do not want
to reserve these CIDRs, set `max_subnet_count` to the number of zones you are actually using.
