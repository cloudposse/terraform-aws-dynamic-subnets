package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test the Terraform module in examples/complete using Terratest

/*
Apply complete! Resources: 23 added, 0 changed, 0 destroyed.

Outputs:

private_subnet_cidrs = [
    172.16.0.0/19,
    172.16.32.0/19,
    172.16.64.0/19,
    172.16.96.0/19
]
public_subnet_cidrs = [
    172.16.128.0/18,
    172.16.192.0/18
]
*/

func TestExamplesComplete(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-west-1.tfvars"},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	privateSubnetCidrs := terraform.OutputList(t, terraformOptions, "private_subnet_cidrs")

	expectedPrivateSubnetCidrs := []string{"172.16.0.0/19", "172.16.32.0/19", "172.16.64.0/19", "172.16.96.0/19"}
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedPrivateSubnetCidrs, privateSubnetCidrs)

	// Run `terraform output` to get the value of an output variable
	publicSubnetCidrs := terraform.OutputList(t, terraformOptions, "public_subnet_cidrs")

	expectedPublicSubnetCidrs := []string{"172.16.128.0/18", "172.16.192.0/18"}
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedPublicSubnetCidrs, publicSubnetCidrs)
}
