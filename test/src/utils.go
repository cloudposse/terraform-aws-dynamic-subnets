package test

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/aws/aws-sdk-go-v2/service/ec2/types"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// cleanup destroys terraform resources with retry logic and verifies EIP cleanup
func cleanup(t *testing.T, terraformOptions *terraform.Options, tempTestFolder string) {
	// Retry terraform destroy up to 3 times with exponential backoff
	maxRetries := 3
	timeBetweenRetries := 10 * time.Second
	description := fmt.Sprintf("Destroying Terraform resources in %s", tempTestFolder)

	_, err := retry.DoWithRetryE(
		t,
		description,
		maxRetries,
		timeBetweenRetries,
		func() (string, error) {
			_, err := terraform.DestroyE(t, terraformOptions)
			if err != nil {
				t.Logf("Terraform destroy attempt failed: %v. Retrying...", err)
				return "", err
			}
			return "Destroy successful", nil
		},
	)

	if err != nil {
		t.Logf("WARNING: Terraform destroy failed after %d retries: %v", maxRetries, err)
		t.Logf("You may need to manually clean up resources")
	}

	// Wait for AWS to fully release resources (especially EIPs)
	t.Log("Waiting for AWS to release resources...")
	time.Sleep(5 * time.Second)

	// Verify EIP cleanup (best effort - don't fail test if verification fails)
	verifyEIPCleanup(t, terraformOptions)

	// Clean up temp folder
	removeErr := os.RemoveAll(tempTestFolder)
	assert.NoError(t, removeErr)
}

// verifyEIPCleanup checks if EIPs with the test's attributes tag have been released
func verifyEIPCleanup(t *testing.T, terraformOptions *terraform.Options) {
	// Only verify if we have attributes (used for tagging)
	attributes, ok := terraformOptions.Vars["attributes"]
	if !ok {
		return
	}

	// Get the attribute value to search for in tags
	var attributeValue string
	switch v := attributes.(type) {
	case []string:
		if len(v) > 0 {
			attributeValue = v[0]
		}
	case string:
		attributeValue = v
	default:
		return
	}

	if attributeValue == "" {
		return
	}

	// Try to load AWS config and check for lingering EIPs
	ctx := context.Background()
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		t.Logf("Could not load AWS config for EIP verification: %v", err)
		return
	}

	ec2Client := ec2.NewFromConfig(cfg)

	// Check for EIPs with our test's tags
	input := &ec2.DescribeAddressesInput{
		Filters: []types.Filter{
			{
				Name:   stringPtr("tag:Attributes"),
				Values: []string{attributeValue},
			},
		},
	}

	result, err := ec2Client.DescribeAddresses(ctx, input)
	if err != nil {
		t.Logf("Could not verify EIP cleanup: %v", err)
		return
	}

	if len(result.Addresses) > 0 {
		t.Logf("WARNING: Found %d EIP(s) that may not have been cleaned up:", len(result.Addresses))
		for _, addr := range result.Addresses {
			t.Logf("  - AllocationId: %s, PublicIp: %s",
				stringValue(addr.AllocationId),
				stringValue(addr.PublicIp))
		}
	} else {
		t.Log("EIP cleanup verified successfully")
	}
}

// Helper functions for AWS SDK
func stringPtr(s string) *string {
	return &s
}

func stringValue(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}
