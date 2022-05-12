## Migration Notes for Dynamic Subnets v2.0

The first version of `terraform-aws-dynamic-subnets` was written for Terraform v0.9.1, 
which was so limited that it do not even have a boolean data type, and 
lists did not have first-class support. Cloud Posse continued to upgrade
the module over time, but retained many of the awkward constructions required
by those early Terraform versions.

Version 2.0 of this module is nearly a complete rewrite, taking advantage 
of the features available in Terraform v1.1, yet attempts to maintain
backward compatibility to a great extent, making migrating to it relatively easy.
Once you have adapted to the new inputs, Terraform should be able to 
plan and apply with no substantive changes. 



#### Changes to Inputs

All the breaking changes are due to changes in inputs. Fortunately, adapting to the 
changes should be easy. In most cases, you simply change the name of the 
input and put the old value inside a list. The notable exception
is [`subnet_type_tag_key`](#subnet_type_tag_key-and-subnet_type_tag_value_format).


## Optional Inputs

Several inputs are optional. Previously, optional inputs were often
`string`s that could be empty or `null`. Unfortunately, due to Terraform [limitations](https://github.com/hashicorp/terraform/issues/26755#issuecomment-719103775),
we cannot condition the creation of a resource based on a value not known at 
plan time, which put severe limitations on when and how this module can be used.
To work around this limitation, any optional string input is now a `list(string)` that can have zero or one element, 
rather than a `string` that could be empty or `null`.

### `cidr_block` replaced with `ipv4_cidr_block`

Previously this module required an IPv4 CIDR block input as `cidr_block`.
This value is now optional, and,  Since we had to make 
a breaking change in type, we took the opportunity to reduce the ambiguity
of `cidr_block` and renamed it `ipv4_cidr_block`.

***Migration***: Replace

```hcl
cidr_block = aws_vpc.main.cidr_block
```

with:

```hcl
ipv4_cidr_block = [aws_vpc.main.cidr_block]
```


### `igw_id`

Like `cidr_block`, the Internet Gateway ID `igw_id`
is now optional, and therefore was changed from `string` to `list(string)`.

***Migration***: Replace

```hcl
igw_id = aws_internet_gateway.default.id
```

with

```hcl
igw_id = [aws_internet_gateway.default.id]
```

Because the Internet Gateway ID is now optional, you
can create a "public" set of subnets but not have the routed directly 
to the internet. You could, instead, route them to a Transit Gateway, 
VPC Endpoint, or other egress by adding your own entry into the route table.


### `subnet_type_tag_key` and `subnet_type_tag_value_format`
The inputs `subnet_type_tag_key` and `subnet_type_tag_value_format` have
been deprecated, and, critically, the default for `subnet_type_tag_key`
has changed from `"cpco.io/subnet/type"` to `null`. This means that
if you did not previously set a value for `subnet_type_tag_key`, your
subnets would have been tagged with the `"cpco.io/subnet/type"` tag in v1.0
and those tags will be removed in v2.0. One mitigating circumstance is
that likely, if you were using the default value, you were not actually
using the resulting tags for anything, so removing the tags will likely
not affect you.

The purpose of these tags was to be used as a filter to `data.aws_subnet_ids`
so you could automatically find all the public or private subnets and not
require them as inputs. Since there was no standard tag key for this purpose,
we provided `subnet_type_tag_key` as an option and automatically generated
those tags with values of either `public` or `private`. Unfortunately,
since there was no standard tag key for this purpose, we created a default
tag key of our own, which is less than ideal.

If you were depending on these tags, then you should have been setting
your own value for `subnet_type_tag_key`, and the good news is that if you
continue to do so, then the tags will continue to be created as before. We do recommend you stop using
these particular tags at some convenient point in the future. If you want to tag public and/or private
subnets in some way to distinguish them, we suggest that instead you look at [standard
tag keys](https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/)
like `kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb`
and add them to `public_subnets_additional_tags` and `private_subnets_additional_tags`
respectively.


### vpc_default_route_table_id -> public_route_table_ids (list)

Providing a route table ID for the public subnets was always optional,
but previously you could only supply a single route table ID to cover
all the public subnets. We have enhanced this feature to allow you to
supply separate route tables for each subnet, and so we have replaced
`vpc_default_route_table_id` with the more powerful `public_route_table_ids` variable.

***Migration***: Replace

```hcl
vpc_default_route_table_id = aws_vpc.main.default_route_table_id
```

with:

```hcl
public_route_table_ids = [aws_vpc.main.default_route_table_id]
```

## Removed variables

### `public_network_acl_id` and `private_network_acl_id`

The variables `public_network_acl_id` and `private_network_acl_id` have been removed.
They did not work properly anyway, so it is unlikely you were using them.
You can now control the creation of network ACLs via `public_open_network_acl_enabled`
and `private_open_network_acl_enabled`.

## Deprecated variables

### `subnet_type_tag_key` and `subnet_type_tag_value_format`

(See [above](#subnet_type_tag_key-and-subnet_type_tag_value_format))

### `aws_route_create_timeout` and `aws_route_delete_timeout`

For clarity and predictability, `aws_route_create_timeout` and `aws_route_delete_timeout`
are deprecated in favor of `route_create_timeout` and `route_delete_timeout`.

Also, the default values have changed from `2m` and `5m` to `5m` and `10m` respectively.

### `root_block_device_encrypted`

For clarity, `root_block_device_encrypted` is deprecated in favor of
`nat_instance_root_block_device_encrypted`.

## Deprecated outputs

### `nat_gateway_public_ips`

This module now uses the same EIPs for both NAT Gateways and NAT instances, so 
that switching from one to the other is possible without changing IPs. 
Therefore the `nat_gateway_public_ips` output is deprecated in favor
of the `nat_ips` output.

