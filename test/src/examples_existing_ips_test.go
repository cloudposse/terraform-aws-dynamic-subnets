package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

// Test the Terraform module in examples/existing-ips using Terratest.
// NOTE: This test creates NAT Gateways/EIPs and runs sequentially to avoid AWS quota limits
func TestExamplesExistingIps(t *testing.T) {
	// Removed t.Parallel() to run sequentially and avoid EIP quota exhaustion
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/existing-ips"
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
	usedNatIps := terraform.OutputList(t, terraformOptions, "nat_ips")
	existingIps := terraform.OutputList(t, terraformOptions, "existing_ips")

	// Verify we're getting back the outputs we expect
	assert.ElementsMatch(t, existingIps, usedNatIps)
}
