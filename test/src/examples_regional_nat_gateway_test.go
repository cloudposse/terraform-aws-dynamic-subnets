package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// Test the Terraform module in examples/regional-nat-gateway using Terratest.
func TestExamplesRegionalNatGateway(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/regional-nat-gateway"
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

	// Run `terraform output` to get the value of an output variable
	natGatewayIds := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")

	// Regional NAT Gateway should create exactly 1 NAT Gateway
	assert.Equal(t, 1, len(natGatewayIds), "Regional NAT Gateway should create exactly 1 NAT Gateway")

	// Verify that the NAT Gateway ID is not empty
	assert.NotEmpty(t, natGatewayIds[0], "NAT Gateway ID should not be empty")

	// Run `terraform output` to get the route table ID
	routeTableId := terraform.Output(t, terraformOptions, "nat_gateway_route_table_id")

	// Verify that the route table ID is not empty
	assert.NotEmpty(t, routeTableId, "Regional NAT Gateway route table ID should not be empty")

	// Run `terraform output` to get private subnet IDs
	privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")

	// Should have created private subnets (3 AZs specified in fixtures)
	assert.Equal(t, 3, len(privateSubnetIds), "Should create 3 private subnets (one per AZ)")

	// Run `terraform output` to get private route table IDs
	privateRouteTableIds := terraform.OutputList(t, terraformOptions, "private_route_table_ids")

	// Should have created only one private route table
	assert.Equal(t, 1, len(privateRouteTableIds), "Should create 1 private route table")
}
