package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test the Terraform module in examples/existing-ips using Terratest.
func TestExamplesExistingIps(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/existing-ips",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	usedNatIps := terraform.OutputList(t, terraformOptions, "nat_ips")
	expectedNatIps := []string{"3.52.100.1", "3.52.100.2", "3.52.100.3"}

	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedNatIps, usedNatIps)
}
