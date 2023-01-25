package test

import (
	"github.com/gruntwork-io/terratest/modules/random"
	teststructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestExamplesMultipleSubnetsPerAZ(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/multiple-subnets-per-az"
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
	privateSubnetCidrs := terraform.OutputList(t, terraformOptions, "private_subnet_cidrs")
	expectedPrivateSubnetCidrs := []string{"172.16.0.0/21", "172.16.8.0/21", "172.16.16.0/21", "172.16.24.0/21", "172.16.32.0/21", "172.16.40.0/21"}
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedPrivateSubnetCidrs, privateSubnetCidrs)

	// Run `terraform output` to get the value of an output variable
	publicSubnetCidrs := terraform.OutputList(t, terraformOptions, "public_subnet_cidrs")
	expectedPublicSubnetCidrs := []string{"172.16.72.0/21", "172.16.80.0/21", "172.16.88.0/21", "172.16.96.0/21", "172.16.104.0/21", "172.16.112.0/21"}
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedPublicSubnetCidrs, publicSubnetCidrs)

	// Run `terraform output` to get the value of an output variable
	namedPrivateSubnetsStatsMap := terraform.OutputMapOfObjects(t, terraformOptions, "named_private_subnets_stats_map")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, len(namedPrivateSubnetsStatsMap), 3)
	assert.Equal(t, len(namedPrivateSubnetsStatsMap["backend"].([]map[string]any)), 2)
	assert.Equal(t, len(namedPrivateSubnetsStatsMap["services"].([]map[string]any)), 2)
	assert.Equal(t, len(namedPrivateSubnetsStatsMap["db"].([]map[string]any)), 2)

	// Run `terraform output` to get the value of an output variable
	namedPublicSubnetsStatsMap := terraform.OutputMapOfObjects(t, terraformOptions, "named_public_subnets_stats_map")
	// Verify we're getting back the outputs we expect
	assert.Equal(t, len(namedPublicSubnetsStatsMap), 3)
	assert.Equal(t, len(namedPublicSubnetsStatsMap["backend"].([]map[string]any)), 2)
	assert.Equal(t, len(namedPublicSubnetsStatsMap["services"].([]map[string]any)), 2)
	assert.Equal(t, len(namedPublicSubnetsStatsMap["db"].([]map[string]any)), 2)
}

func TestExamplesMultipleSubnetsPerAZDisabled(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/multiple-subnets-per-az"
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
			"enabled":    false,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	results := terraform.InitAndApply(t, terraformOptions)

	// Should complete successfully without creating or changing any resources
	assert.Contains(t, results, "Resources: 0 added, 0 changed, 0 destroyed.")
}
