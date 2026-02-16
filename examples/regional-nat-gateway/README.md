# Regional NAT Gateway Example

This example demonstrates how to use the Regional NAT Gateway feature, which was introduced by AWS to simplify network architecture and provide automatic high availability across Availability Zones.

## Key Features of Regional NAT Gateway

- **Simplified Architecture**: Single NAT Gateway ID that automatically expands across all AZs
- **No Public Subnets Required**: Regional NAT Gateways don't need to be placed in public subnets, enhancing security
- **Automatic High Availability**: Automatically expands and contracts with your workload footprint
- **Higher Limits**: Supports up to 32 IP addresses per AZ (vs 8 for zonal NAT gateways)
- **Cost Optimization**: Simpler to manage and can reduce operational overhead

## Configuration

This example creates:
- A VPC with IPv4 CIDR block
- Private subnets across multiple availability zones
- A single Regional NAT Gateway that automatically provides NAT services across all AZs
- Route tables configured to route traffic through the Regional NAT Gateway

## Key Differences from Zonal NAT Gateway

### Zonal NAT Gateway (Traditional)
```hcl
module "subnets" {
  source = "cloudposse/dynamic-subnets/aws"
  
  nat_gateway_enabled           = true
  nat_gateway_availability_mode = "zonal"  # or omit (default)
  public_subnets_enabled        = true     # Required for zonal NAT
  private_subnets_enabled       = true
  # Creates one NAT per AZ in public subnets
}
```

### Regional NAT Gateway (New)
```hcl
module "subnets" {
  source = "cloudposse/dynamic-subnets/aws"
  
  nat_gateway_enabled           = true
  nat_gateway_availability_mode = "regional"
  public_subnets_enabled        = false    # Not required for regional NAT
  private_subnets_enabled       = true
  # Creates one Regional NAT that spans all AZs
}
```

## Usage

To run this example:

```bash
terraform init
terraform plan -var-file=fixtures.us-east-2.tfvars
terraform apply -var-file=fixtures.us-east-2.tfvars
```

## Important Notes

1. **Regional NAT Gateways only support public connectivity** - they cannot be used for private NAT use cases
2. **Automatic expansion takes up to 60 minutes** - when you launch resources in a new AZ, the Regional NAT Gateway may take up to 60 minutes to expand to that zone
3. **Internet Gateway is required** - Regional NAT Gateways need an Internet Gateway in the VPC
4. **Backward compatible** - Existing configurations continue to work with the default `zonal` mode

## When to Use Regional NAT Gateway

Consider using Regional NAT Gateways for:
- New deployments where you want simplified architecture
- Workloads that dynamically scale across AZs
- Environments where you want to minimize public subnet exposure
- Applications that can tolerate the 60-minute expansion window

Use Zonal NAT Gateways for:
- Private NAT use cases (connectivity_type = "private")
- Workloads requiring immediate NAT availability in new AZs
- Existing deployments where migration complexity outweighs benefits

## Outputs

- `nat_gateway_ids` - The ID of the Regional NAT Gateway
- `nat_gateway_route_table_id` - The automatically created route table for the Regional NAT Gateway
- `nat_gateway_regional_addresses` - Information about IP addresses and network interfaces across AZs
- `private_subnet_ids` - IDs of the private subnets created
