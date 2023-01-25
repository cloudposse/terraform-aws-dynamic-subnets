package test

import (
	"github.com/gruntwork-io/terratest/modules/random"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test the Terraform module in examples/existing-ips using Terratest.
func TestExamplesExistingIps(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/existing-ips"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := teststructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

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

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	usedNatIps := terraform.OutputList(t, terraformOptions, "nat_ips")
	existingIps := terraform.OutputList(t, terraformOptions, "existing_ips")

	// Verify we're getting back the outputs we expect
	assert.ElementsMatch(t, existingIps, usedNatIps)
}
