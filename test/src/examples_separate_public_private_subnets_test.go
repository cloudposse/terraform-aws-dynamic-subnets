package test

import (
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"k8s.io/apimachinery/pkg/util/runtime"
)

// Test separate public/private subnet counts with NAT by name
func TestExamplesSeparatePublicPrivateSubnets(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/separate-public-private-subnets"
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

	// If Go runtime crushes, run `terraform destroy` to clean up any resources that were created
	defer runtime.HandleCrash(func(i interface{}) {
		cleanup(t, terraformOptions, tempTestFolder)
	})

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Verify private subnets
	// 3 AZs × 3 private subnets per AZ = 9 private subnets
	privateSubnetCidrs := terraform.OutputList(t, terraformOptions, "private_subnet_cidrs")
	assert.Equal(t, 9, len(privateSubnetCidrs), "Should have 9 private subnets (3 per AZ × 3 AZs)")

	// Verify public subnets
	// 3 AZs × 2 public subnets per AZ = 6 public subnets
	publicSubnetCidrs := terraform.OutputList(t, terraformOptions, "public_subnet_cidrs")
	assert.Equal(t, 6, len(publicSubnetCidrs), "Should have 6 public subnets (2 per AZ × 3 AZs)")

	// Verify NAT Gateways
	// 1 NAT per AZ × 3 AZs = 3 NAT Gateways
	natGatewayIds := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")
	assert.Equal(t, 3, len(natGatewayIds), "Should have 3 NAT Gateways (1 per AZ)")

	// Verify named subnet maps
	namedPrivateSubnetsMap := terraform.OutputMapOfObjects(t, terraformOptions, "named_private_subnets_map")
	assert.Equal(t, 3, len(namedPrivateSubnetsMap), "Should have 3 named private subnet groups")
	assert.Contains(t, namedPrivateSubnetsMap, "database", "Should have 'database' subnet group")
	assert.Contains(t, namedPrivateSubnetsMap, "app1", "Should have 'app1' subnet group")
	assert.Contains(t, namedPrivateSubnetsMap, "app2", "Should have 'app2' subnet group")

	// Each named group should have 3 subnets (one per AZ)
	assert.Equal(t, 3, len(namedPrivateSubnetsMap["database"].([]interface{})), "database group should have 3 subnets")
	assert.Equal(t, 3, len(namedPrivateSubnetsMap["app1"].([]interface{})), "app1 group should have 3 subnets")
	assert.Equal(t, 3, len(namedPrivateSubnetsMap["app2"].([]interface{})), "app2 group should have 3 subnets")

	namedPublicSubnetsMap := terraform.OutputMapOfObjects(t, terraformOptions, "named_public_subnets_map")
	assert.Equal(t, 2, len(namedPublicSubnetsMap), "Should have 2 named public subnet groups")
	assert.Contains(t, namedPublicSubnetsMap, "loadbalancer", "Should have 'loadbalancer' subnet group")
	assert.Contains(t, namedPublicSubnetsMap, "web", "Should have 'web' subnet group")

	// Each named group should have 3 subnets (one per AZ)
	assert.Equal(t, 3, len(namedPublicSubnetsMap["loadbalancer"].([]interface{})), "loadbalancer group should have 3 subnets")
	assert.Equal(t, 3, len(namedPublicSubnetsMap["web"].([]interface{})), "web group should have 3 subnets")

	// Verify route tables
	// One route table per private subnet = 9
	privateRouteTables := terraform.OutputList(t, terraformOptions, "private_route_table_ids")
	assert.Equal(t, 9, len(privateRouteTables), "Should have 9 private route tables (one per private subnet)")

	// Public route tables depend on configuration, but should exist
	publicRouteTables := terraform.OutputList(t, terraformOptions, "public_route_table_ids")
	assert.Greater(t, len(publicRouteTables), 0, "Should have at least one public route table")
}

func TestExamplesSeparatePublicPrivateSubnetsDisabled(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/separate-public-private-subnets"
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
			"enabled":    false,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	results := terraform.InitAndApply(t, terraformOptions)

	// Should complete successfully without creating or changing any resources.
	// Extract the "Resources:" section of the output to make the error message more readable.
	re := regexp.MustCompile(`Resources: [^.]+\.`)
	match := re.FindString(results)
	assert.Equal(t, "Resources: 0 added, 0 changed, 0 destroyed.", match, "Applying with enabled=false should not create any resources")
}
