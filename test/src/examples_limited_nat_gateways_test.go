package test

import (
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// TestExamplesLimitedNatGateways tests the max_nats feature where NAT Gateways are limited to fewer than the number of AZs
// This is the critical test case that would have caught the bug fixed in commit 3681299
// NOTE: This test creates NAT Gateways/EIPs and runs sequentially to avoid AWS quota limits
func TestExamplesLimitedNatGateways(t *testing.T) {
	// Removed t.Parallel() to run sequentially and avoid EIP quota exhaustion
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/limited-nat-gateways"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
			// Test with 3 AZs but only 1 NAT
			// This is the scenario that triggered the bug
			"max_nats": 1,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

	// If Go runtime panics, run `terraform destroy` to clean up any resources that were created
	defer func() {
		if r := recover(); r != nil {
			cleanup(t, terraformOptions, tempTestFolder)
			panic(r) // Re-panic after cleanup
		}
	}()

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Verify private subnets
	// 3 AZs × 1 private subnet per AZ (default) = 3 private subnets
	privateSubnetCidrs := terraform.OutputList(t, terraformOptions, "private_subnet_cidrs")
	assert.Equal(t, 3, len(privateSubnetCidrs), "Should have 3 private subnets (1 per AZ × 3 AZs)")

	// Verify public subnets
	// 3 AZs × 1 public subnet per AZ (default) = 3 public subnets
	publicSubnetCidrs := terraform.OutputList(t, terraformOptions, "public_subnet_cidrs")
	assert.Equal(t, 3, len(publicSubnetCidrs), "Should have 3 public subnets (1 per AZ × 3 AZs)")

	// Verify NAT Gateways - THIS IS THE KEY TEST
	// max_nats=1 should create only 1 NAT Gateway (in first AZ only)
	// This is a cost optimization - subnets in AZ2 and AZ3 will route through the NAT in AZ1
	natGatewayIds := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")
	assert.Equal(t, 1, len(natGatewayIds), "Should have only 1 NAT Gateway despite having 3 AZs (max_nats=1)")

	// Verify only 1 EIP was allocated
	natIps := terraform.OutputList(t, terraformOptions, "nat_ips")
	assert.Equal(t, 1, len(natIps), "Should have only 1 Elastic IP for the single NAT Gateway")

	// Verify route tables
	// One route table per private subnet = 3
	// All 3 should successfully reference the 1 NAT Gateway (this is what the bug broke)
	privateRouteTables := terraform.OutputList(t, terraformOptions, "private_route_table_ids")
	assert.Equal(t, 3, len(privateRouteTables), "Should have 3 private route tables (one per private subnet)")

	// Verify AZ distribution
	azPrivateSubnetsMap := terraform.OutputMapOfObjects(t, terraformOptions, "az_private_subnets_map")
	assert.Equal(t, 3, len(azPrivateSubnetsMap), "Should have subnets distributed across 3 AZs")

	// Each AZ should have 1 private subnet
	for az := range azPrivateSubnetsMap {
		subnets := azPrivateSubnetsMap[az].([]interface{})
		assert.Equal(t, 1, len(subnets), "Each AZ should have 1 private subnet")
	}
}

// TestExamplesLimitedNatGatewaysTwoNats tests with max_nats=2 and 3 AZs
// This ensures the formula works correctly when max_nats is between 1 and total AZs
func TestExamplesLimitedNatGatewaysTwoNats(t *testing.T) {
	// Removed t.Parallel() to run sequentially and avoid EIP quota exhaustion
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/limited-nat-gateways"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		VarFiles:     varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
			// Test with 3 AZs but only 2 NATs
			// NATs in AZ1 and AZ2, AZ3 subnets route through AZ1 or AZ2
			"max_nats": 2,
		},
	}

	defer cleanup(t, terraformOptions, tempTestFolder)

	defer func() {
		if r := recover(); r != nil {
			cleanup(t, terraformOptions, tempTestFolder)
			panic(r)
		}
	}()

	terraform.InitAndApply(t, terraformOptions)

	// Verify NAT Gateways
	natGatewayIds := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")
	assert.Equal(t, 2, len(natGatewayIds), "Should have 2 NAT Gateways (max_nats=2)")

	// Verify route tables still work for all 3 AZs
	privateRouteTables := terraform.OutputList(t, terraformOptions, "private_route_table_ids")
	assert.Equal(t, 3, len(privateRouteTables), "Should have 3 private route tables")
}

func TestExamplesLimitedNatGatewaysDisabled(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/limited-nat-gateways"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		VarFiles:     varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
			"enabled":    false,
		},
	}

	defer cleanup(t, terraformOptions, tempTestFolder)

	results := terraform.InitAndApply(t, terraformOptions)

	// Should complete successfully without creating or changing any resources
	re := regexp.MustCompile(`Resources: [^.]+\.`)
	match := re.FindString(results)
	assert.Equal(t, "Resources: 0 added, 0 changed, 0 destroyed.", match, "Applying with enabled=false should not create any resources")
}
