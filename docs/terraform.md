## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| attributes | Additional attributes (e.g. `policy` or `role`) | list | `<list>` | no |
| availability_zones | List of Availability Zones where subnets will be created | list | - | yes |
| cidr_block | Base CIDR block which will be divided into subnet CIDR blocks (e.g. `10.0.0.0/16`) | string | - | yes |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name`, and `attributes` | string | `-` | no |
| igw_id | Internet Gateway ID the public route table will point to (e.g. `igw-9c26a123`) | string | - | yes |
| map_public_ip_on_launch | Instances launched into a public subnet should be assigned a public IP address | string | `true` | no |
| max_subnet_count | Sets the maximum amount of subnets to deploy.  0 will deploy a subnet for every availablility zone within the region | string | `0` | no |
| name | Name (e.g. `app`) | string | - | yes |
| namespace | Namespace (e.g. `cp` or `cloudposse`) | string | - | yes |
| nat_gateway_enabled | Flag to enable/disable NAT gateways for private subnets | string | `true` | no |
| private_network_acl_id | Network ACL ID that will be added to private subnets. If empty, a new ACL will be created | string | `` | no |
| public_network_acl_id | Network ACL ID that will be added to public subnets. If empty, a new ACL will be created | string | `` | no |
| region | AWS Region (e.g. `us-east-1`) | string | - | yes |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | string | - | yes |
| tags | Additional tags (e.g. map(`Cluster`,`XYZ`) | map | `<map>` | no |
| vpc_default_route_table_id | Default route table for public subnets. If not set, will be created. (e.g. `rtb-f4f0ce12`) | string | `` | no |
| vpc_id | VPC ID where subnets will be created (e.g. `vpc-aceb2723`) | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| private_route_table_ids | AWS ID of the created private route table |
| private_subnet_cidrs | CIDR of the created private subnet |
| private_subnet_ids | AWS ID of the created private subnet |
| public_route_table_ids | AWS ID of the created public route table |
| public_subnet_cidrs | CIDR of the created public subnet |
| public_subnet_ids | AWS ID of the created public subnet |

