## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| additional_tag_map | Additional tags for appending to each tag map | map | `<map>` | no |
| attributes | Any extra attributes for naming these resources | list | `<list>` | no |
| availability_zones | List of Availability Zones where subnets will be created. When none provided, all availability zones will be used up to the number provided in the max_public_subnet_count and/or max_private_subnet_count | list | `<list>` | no |
| cidr_block | Base CIDR block which will be divided into subnet CIDR blocks (e.g. `10.0.0.0/16`), or pass in the vpc_id to use the CIDR from the VPC | string | `` | no |
| context | The context output from an external label module to pass to the label modules within this module | map | `<map>` | no |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name` and `attributes` | string | `-` | no |
| environment | The environment name if not using stage | string | `` | no |
| igw_id | Internet Gateway ID the public route table will point to (e.g. `igw-9c26a123`) | string | - | yes |
| label_order | The naming order of the id output and Name tag | list | `<list>` | no |
| map_public_ip_on_launch | Instances launched into a public subnet should be assigned a public IP address | string | `true` | no |
| max_subnet_count | The maximum number of subnets to deploy. 0 for none, -1 to match the number of az's in the region, or a specific number | string | `-1` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | string | `` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | string | `` | no |
| nat_gateway_enabled | Flag to enable/disable NAT Gateways to allow servers in the private subnets to access the Internet | string | `true` | no |
| nat_instance_enabled | Flag to enable/disable NAT Instances to allow servers in the private subnets to access the Internet | string | `false` | no |
| nat_instance_type | NAT Instance type | string | `t3.micro` | no |
| private_network_acl_id | Network ACL ID that will be added to private subnets. If empty, a new ACL will be created | string | `` | no |
| private_subnet_count | Sets the amount of private subnets to deploy.  -1 will deploy a subnet for every availablility zone within the region, 0 will deploy no subnets. The AZ's supplied will be cycled through to create the subnets | string | `-1` | no |
| public_network_acl_id | Network ACL ID that will be added to public subnets. If empty, a new ACL will be created | string | `` | no |
| public_subnet_count | Sets the amount of public subnets to deploy.  -1 will deploy a subnet for every availablility zone within the region, 0 will deploy no subnets. The AZ's supplied will be cycled through to create the subnets | string | `-1` | no |
| regex_replace_chars | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`. By default only hyphens, letters and digits are allowed, all other chars are removed | string | `/[^a-zA-Z0-9-]/` | no |
| region | AWS Region (e.g. `us-east-1`) | string | - | yes |
| stage | Stage, e.g. 'prod', 'staging', 'dev', or 'test' | string | `` | no |
| subnet_type_tag_key | Key for subnet type tag to provide information about the type of subnets, e.g. `cpco.io/subnet/type=private` or `cpco.io/subnet/type=public` | string | `cpco.io/subnet/type` | no |
| subnet_type_tag_value_format | This is using the format interpolation symbols to allow the value of the subnet_type_tag_key to be modified. | string | `%s` | no |
| tags | Additional tags to apply to all resources that use this label module | map | `<map>` | no |
| vpc_default_route_table_id | Default route table for public subnets. If not set, will be created. (e.g. `rtb-f4f0ce12`) | string | `` | no |
| vpc_id | VPC ID where subnets will be created (e.g. `vpc-aceb2723`) | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| availability_zones | List of Availability Zones where subnets were created |
| availability_zones_private | List of private Availability Zones where subnets were created |
| availability_zones_public | List of public Availability Zones where subnets were created |
| nat_gateway_ids | IDs of the NAT Gateways created |
| nat_instance_ids | IDs of the NAT Instances created |
| private_route_table_ids | IDs of the created private route tables |
| private_subnet_cidrs | CIDR blocks of the created private subnets |
| private_subnet_ids | IDs of the created private subnets |
| public_route_table_ids | IDs of the created public route tables |
| public_subnet_cidrs | CIDR blocks of the created public subnets |
| public_subnet_ids | IDs of the created public subnets |

