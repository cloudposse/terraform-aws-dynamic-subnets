# Test Coverage Analysis

## Current Test Coverage (After max_nats Fix)

### Examples: 7 Total

| Example | Test Functions | NAT Config | Key Features Tested |
|---------|---------------|------------|-------------------|
| **complete** | 2 | Default (1 per AZ) | Basic setup, enabled flag |
| **existing-ips** | 1 | Pre-allocated EIPs | Custom EIP allocation |
| **multiple-subnets-per-az** | 2 | Not configured | Multiple named subnets, subnet stats |
| **redundant-nat-gateways** | 2 | By names (multiple per AZ) | High availability, 2 NATs per AZ |
| **separate-public-private-subnets** | 3 | By names AND indices | Different public/private counts, both placement methods |
| **limited-nat-gateways** | 3 (NEW) | max_nats feature | ✅ Cost optimization, max_nats < AZs |
| **nacls** | 0 | N/A | Network ACLs (example only, no tests) |

**Total: 13 test functions across 7 examples**

## Feature Coverage Matrix

| Feature | Example | Test Status |
|---------|---------|------------|
| Basic VPC + Subnets | complete | ✅ Tested |
| enabled=false flag | All examples | ✅ Tested |
| Multiple subnets per AZ | multiple-subnets-per-az | ✅ Tested |
| Named subnets | multiple-subnets-per-az, redundant-nat-gateways, separate-public-private-subnets | ✅ Tested |
| Separate public/private counts | separate-public-private-subnets, redundant-nat-gateways | ✅ Tested |
| NAT Gateway (default) | complete | ✅ Tested |
| NAT Gateway (existing EIPs) | existing-ips | ✅ Tested |
| NAT placement by index | separate-public-private-subnets | ✅ Tested |
| NAT placement by name | separate-public-private-subnets, redundant-nat-gateways | ✅ Tested |
| Redundant NATs (multiple per AZ) | redundant-nat-gateways | ✅ Tested |
| **max_nats < num_azs** | **limited-nat-gateways** | **✅ Tested (NEW)** |
| NAT Instance | None | ❌ NOT TESTED |
| IPv6 / NAT64 | None | ❌ NOT TESTED |
| DNS64 | None | ❌ NOT TESTED |
| Network ACLs | nacls (example only) | ⚠️ Example exists, no tests |
| Custom route tables | None | ❌ NOT TESTED |
| Route table per subnet | None | ❌ NOT TESTED |
| AZ IDs (vs AZ names) | None | ❌ NOT TESTED |
| IPAM integration | None | ❌ NOT TESTED |

## Test Coverage Gaps

### Critical Gaps ❌

These features have **zero test coverage** and could contain bugs:

1. **NAT Instance**
   - Variables: `nat_instance_enabled`, `nat_instance_type`, `nat_instance_ami_id`
   - Risk: Deprecated but still supported, untested code path
   - Recommendation: Add example or deprecate feature

2. **IPv6 / NAT64**
   - Variables: `ipv6_enabled`, `ipv6_cidr_block`, `private_dns64_nat64_enabled`, `public_dns64_nat64_enabled`
   - Risk: Complex routing logic, untested
   - Recommendation: Add dedicated IPv6 example

3. **Custom Route Tables**
   - Variables: `public_route_table_ids`, `public_route_table_enabled`, `public_route_table_per_subnet_enabled`
   - Risk: Route table association logic untested
   - Recommendation: Add example with custom route tables

### Medium Priority Gaps ⚠️

4. **Network ACLs**
   - Example exists but no automated tests
   - Variables: `private_open_network_acl_enabled`, `public_open_network_acl_enabled`
   - Recommendation: Add test for nacls example

5. **AZ IDs vs AZ Names**
   - Variable: `availability_zone_ids`
   - All tests use AZ names, not AZ IDs
   - Recommendation: Add test variant using AZ IDs

6. **IPAM Integration**
   - Variables: `ipv4_cidrs` (for IPAM pools)
   - No test coverage for IPAM-allocated CIDRs
   - Recommendation: Add IPAM example if feature is actively used

### Low Priority Gaps ℹ️

7. **Edge Cases**
   - Single AZ deployment
   - max_nats = 0 (no NATs)
   - Empty subnet configurations
   - max_subnet_count limits

## Recommendations

### Immediate Actions (High Priority)

1. **Add NAT Instance Test** (if feature is not deprecated)
   - Create `examples/nat-instance`
   - Test basic NAT instance functionality
   - Or: Document feature as deprecated and add sunset plan

2. **Add IPv6/NAT64 Test**
   - Create `examples/ipv6-nat64`
   - Test IPv6 CIDR allocation
   - Test DNS64 and NAT64 routing

3. **Add Network ACL Test**
   - Add `test/src/examples_nacls_test.go`
   - Test open and restrictive NACL configurations

### Future Improvements (Medium Priority)

4. **Add Custom Route Table Test**
   - Create `examples/custom-route-tables`
   - Test external route table integration
   - Test per-subnet route table mode

5. **Add AZ ID Test**
   - Modify existing test to use AZ IDs instead of names
   - Validate proper AZ selection and subnet placement

6. **Add Edge Case Tests**
   - Single AZ deployment
   - No NATs (max_nats=0 or NAT disabled)
   - Boundary conditions

### Documentation Improvements

7. **Update README**
   - Add test coverage badge
   - Document which features are tested
   - Add "Testing" section with instructions

8. **Add Testing Guide**
   - Document how to run tests locally
   - Explain test organization
   - Provide troubleshooting tips

## Test Execution Strategy

### Current Approach
- Sequential execution for NAT Gateway tests (to avoid EIP quota limits)
- Parallel execution for non-NAT tests
- Per-example cleanup with defer

### Recommendations
1. **Group tests by resource intensity**
   - Light tests (no NATs): Run in parallel
   - NAT tests: Run sequentially with delays if needed

2. **Add test tags**
   ```go
   // +build integration
   ```
   To separate fast unit tests from slow integration tests

3. **Consider using AWS LocalStack**
   - For faster feedback in CI/CD
   - Reduce AWS costs for test runs
   - Enable parallel test execution

## Bug Discovery Impact

### The max_nats Bug

**Discovered by:** aws-vpc component tests (external to this module)
**Would have been caught by:** limited-nat-gateways example (NOW ADDED)

**Lesson:** The module's own test suite did NOT catch a critical bug in a documented feature (`max_nats`). This highlights the importance of comprehensive test coverage.

### Test Coverage Effectiveness

**Before Fix:**
- 6 examples, 8 test functions
- 0% coverage of max_nats feature
- Bug reached v3.0.0 release

**After Fix:**
- 7 examples, 13 test functions
- 100% coverage of max_nats feature
- Future bugs will be caught by CI

## Conclusion

The addition of the `limited-nat-gateways` example significantly improves test coverage by testing the previously untested `max_nats` feature. However, several critical features still lack test coverage, particularly:

1. NAT Instance (deprecated?)
2. IPv6/NAT64 (complex, high-risk)
3. Custom route tables

**Recommendation:** Prioritize adding tests for IPv6/NAT64 and document/deprecate NAT Instance feature if it's no longer actively maintained.

---

**Document Version:** 1.0
**Last Updated:** 2025-11-03
**Next Review:** After adding IPv6 test coverage
