# Limited NAT Gateways Example

This example demonstrates the `max_nats` feature for cost optimization by creating fewer NAT Gateways than Availability Zones.

## Use Case

NAT Gateways are expensive ($0.045/hour + data transfer costs). In non-production environments or cost-sensitive deployments, you may want to reduce costs by:
- Using only 1 NAT Gateway for all AZs (this example)
- Using fewer NATs than AZs (e.g., 2 NATs across 3 AZs)

**Trade-off:** Lower availability and potential cross-AZ data transfer costs, but significant infrastructure cost savings.

## Configuration

This example creates:
- **3 Availability Zones** (us-east-2a, us-east-2b, us-east-2c)
- **3 Public Subnets** (1 per AZ)
- **3 Private Subnets** (1 per AZ)
- **1 NAT Gateway** (only in first AZ via `max_nats = 1`)

### Routing Behavior

With `max_nats = 1`:
- Private subnet in **AZ-a** → Routes to NAT Gateway in AZ-a ✅
- Private subnet in **AZ-b** → Routes to NAT Gateway in AZ-a (cross-AZ) ⚠️
- Private subnet in **AZ-c** → Routes to NAT Gateway in AZ-a (cross-AZ) ⚠️

This configuration significantly reduces costs but:
- If AZ-a fails, private subnets in all AZs lose internet connectivity
- Cross-AZ data transfer incurs additional charges

## Testing the Bug Fix

This example specifically tests the bug that was fixed in commit 3681299. Without that fix, the following error would occur:

```
Error: Invalid index
  on .terraform/modules/subnets/nat-gateway.tf line 40, in resource "aws_route" "nat4":
  40:   nat_gateway_id = aws_nat_gateway.default[local.private_route_table_to_nat_map[count.index]].id
    ├────────────────
    │ aws_nat_gateway.default is tuple with 1 element
    │ count.index is 1
    │ local.private_route_table_to_nat_map is list of number with 3 elements

The given key does not identify an element in this collection value: the
given index is greater than or equal to the length of the collection.
```

The bug was that route tables in AZs without NATs tried to reference non-existent NAT indices.

## Usage

```hcl
module "subnets" {
  source = "cloudposse/dynamic-subnets/aws"

  # ... other configuration ...

  # Limit NAT Gateways to reduce costs
  max_nats = 1  # Only create 1 NAT despite having 3 AZs

  nat_gateway_enabled  = true
  nat_instance_enabled = false
}
```

## Cost Comparison

**Standard Setup (3 NATs):**
- 3 NAT Gateways × $32.40/month = $97.20/month
- High availability (each AZ has its own NAT)
- No cross-AZ data transfer for NAT traffic

**Limited Setup (1 NAT):**
- 1 NAT Gateway × $32.40/month = $32.40/month
- Savings: $64.80/month (67% reduction) 💰
- Lower availability (single point of failure)
- Additional cross-AZ data transfer charges

## When to Use This Pattern

✅ **Good for:**
- Development environments
- Testing environments
- Cost-sensitive non-production workloads
- Scenarios where availability is less critical than cost

❌ **Avoid for:**
- Production environments requiring high availability
- Workloads with strict SLAs
- Applications that cannot tolerate AZ-level failures
- High-bandwidth workloads (cross-AZ transfer costs may exceed NAT savings)

## Related Examples

- `examples/complete` - Standard setup with 1 NAT per AZ
- `examples/redundant-nat-gateways` - High availability with multiple NATs per AZ
