#!/bin/bash
# Azure Excel Compatibility Lab - Destroy Script
# Destroys all resources created by Terraform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}=== Azure Excel Compatibility Lab - DESTROY ===${NC}"
echo ""

cd "$TERRAFORM_DIR"

# Check if there's state to destroy
if [ ! -f "terraform.tfstate" ] && [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}No Terraform state found. Nothing to destroy.${NC}"
    exit 0
fi

# Show what will be destroyed
echo -e "${YELLOW}The following resources will be destroyed:${NC}"
terraform state list 2>/dev/null || echo "Unable to list state"
echo ""

# Confirm destruction
read -p "Are you sure you want to destroy all resources? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Destruction cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Destroying resources...${NC}"

# Azure refuses to delete VM extensions while the VM is stopped/deallocated
# (e.g. after a Spot eviction). Extensions are removed with the VM anyway,
# so drop them from state instead of deleting them individually.
for ext in $(terraform state list 2>/dev/null | grep '^azurerm_virtual_machine_extension\.' || true); do
    echo "Removing $ext from state (deleted together with the VM)"
    terraform state rm "$ext" >/dev/null
done

terraform destroy -auto-approve

echo ""
echo -e "${GREEN}=== Resources Destroyed ===${NC}"
echo "All Azure resources have been deleted."
echo "No further charges will be incurred for this deployment."

# Clean up local files
echo ""
read -p "Clean up local Terraform files? (yes/no): " cleanup
if [ "$cleanup" == "yes" ]; then
    rm -rf .terraform .terraform.lock.hcl terraform.tfstate* tfplan
    echo -e "${GREEN}Local files cleaned up.${NC}"
fi
