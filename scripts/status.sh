#!/bin/bash
# Azure Excel Compatibility Lab - Status Script
# Shows the current status of deployed resources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Azure Excel Compatibility Lab - Status ===${NC}"
echo ""

cd "$TERRAFORM_DIR"

# Check if there's state
if [ ! -f "terraform.tfstate" ]; then
    echo -e "${YELLOW}No deployment found.${NC}"
    echo "Run ./scripts/deploy.sh to create a new VM."
    exit 0
fi

# Show Terraform outputs
echo -e "${GREEN}Current Deployment:${NC}"
echo ""
terraform output 2>/dev/null || echo "Unable to get outputs"

# Get VM status from Azure if logged in
echo ""
echo -e "${GREEN}Azure VM Status:${NC}"
VM_NAME=$(terraform output -raw vm_name 2>/dev/null || echo "")
RG_NAME=$(terraform output -raw resource_group_name 2>/dev/null || echo "")

if [ -n "$VM_NAME" ] && [ -n "$RG_NAME" ]; then
    az vm show -g "$RG_NAME" -n "$VM_NAME" --show-details --query "{Name:name, Status:powerState, PublicIP:publicIps, Size:hardwareProfile.vmSize}" -o table 2>/dev/null || echo "Unable to get VM status (not logged in or VM deleted)"
else
    echo "Unable to determine VM details"
fi

echo ""
echo -e "${YELLOW}Commands:${NC}"
echo "  Start VM:   az vm start -g $RG_NAME -n $VM_NAME"
echo "  Stop VM:    az vm deallocate -g $RG_NAME -n $VM_NAME"
echo "  Destroy:    ./scripts/destroy.sh"
