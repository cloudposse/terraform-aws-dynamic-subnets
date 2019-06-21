## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| additional_tag_map | Additional tags for appending to each tag map | map(string) | `<map>` | no |
| attributes | Any extra attributes for naming these resources | list(string) | `<list>` | no |
| availability_zones | List of Availability Zones where subnets will be created | list(string) | - | yes |
| cidr_block | Base CIDR block which will be divided into subnet CIDR blocks (e.g. `10.0.0.0/16`) | string | - | yes |
| context | Default context to use for passing state between label invocations | object | `<map>` | no |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name` and `attributes` | string | `-` | no |
| environment | The environment name if not using stage | string | `` | no |
| igw_id | Internet Gateway ID the public route table will point to (e.g. `igw-9c26a123`) | string | - | yes |
| label_order | The naming order of the ID output and Name tag | list(string) | `<list>` | no |
| map_public_ip_on_launch | Instances launched into a public subnet should be assigned a public IP address | bool | `true` | no |
| max_subnet_count | Sets the maximum amount of subnets to deploy. 0 will deploy a subnet for every provided availablility zone (in `availability_zones` variable) within the region | string | `0` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | string | `` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | string | `` | no |
| nat_gateway_enabled | Flag to enable/disable NAT Gateways to allow servers in the private subnets to access the Internet | bool | `true` | no |
| nat_instance_enabled | Flag to enable/disable NAT Instances to allow servers in the private subnets to access the Internet | bool | `false` | no |
| nat_instance_type | NAT Instance type | string | `t3.micro` | no |
| private_network_acl_id | Network ACL ID that will be added to private subnets. If empty, a new ACL will be created | string | `` | no |
| public_network_acl_id | Network ACL ID that will be added to public subnets. If empty, a new ACL will be created | string | `` | no |
| regex_replace_chars | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`. By default only hyphens, letters and digits are allowed, all other chars are removed | string | `/[^a-zA-Z0-9-]/` | no |
| stage | Stage, e.g. 'prod', 'staging', 'dev', or 'test' | string | `` | no |
| subnet_type_tag_key | Key for subnet type tag to provide information about the type of subnets, e.g. `cpco.io/subnet/type=private` or `cpco.io/subnet/type=public` | string | `cpco.io/subnet/type` | no |
| subnet_type_tag_value_format | This is using the format interpolation symbols to allow the value of the subnet_type_tag_key to be modified. | string | `%s` | no |
| tags | Additional tags to apply to all resources that use this label module | map(string) | `<map>` | no |
| vpc_default_route_table_id | Default route table for public subnets. If not set, will be created. (e.g. `rtb-f4f0ce12`) | string | `` | no |
| vpc_id | VPC ID where subnets will be created (e.g. `vpc-aceb2723`) | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| availability_zones | List of Availability Zones where subnets were created |
| nat_gateway_ids | IDs of the NAT Gateways created |
| nat_instance_ids | IDs of the NAT Instances created |
| private_route_table_ids | IDs of the created private route tables |
| private_subnet_cidrs | CIDR blocks of the created private subnets |
| private_subnet_ids | IDs of the created private subnets |
| public_route_table_ids | IDs of the created public route tables |
| public_subnet_cidrs | CIDR blocks of the created public subnets |
| public_subnet_ids | IDs of the created public subnets |

