#!/bin/bash
# Azure Excel Compatibility Lab - Deploy Script
# Deploys a Windows VM with the specified Excel version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

# Default values
EXCEL_VERSION="${1:-2019}"
LOCATION="${2:-eastus}"
VM_SIZE="${3:-Standard_D2s_v3}"
USE_SPOT="${4:-true}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Azure Excel Compatibility Lab ===${NC}"
echo -e "Excel version: $EXCEL_VERSION"
echo -e "Location:      $LOCATION"
echo -e "VM size:       $VM_SIZE"
echo -e "Spot VM:       $USE_SPOT"
echo ""

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    if ! command -v az &> /dev/null; then
        echo -e "${RED}Error: Azure CLI is not installed${NC}"
        echo "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi

    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Error: Terraform is not installed${NC}"
        echo "Install from: https://www.terraform.io/downloads"
        exit 1
    fi

    # Check Azure login
    if ! az account show &> /dev/null; then
        echo -e "${YELLOW}Not logged in to Azure. Running 'az login'...${NC}"
        az login
    fi

    echo -e "${GREEN}Prerequisites OK${NC}"
}

# Validate Excel version
validate_version() {
    case $EXCEL_VERSION in
        2016|2019|2021)
            echo -e "${GREEN}Excel version: $EXCEL_VERSION${NC}"
            ;;
        *)
            echo -e "${RED}Error: Invalid Excel version '$EXCEL_VERSION'${NC}"
            echo "Valid versions: 2016, 2019, 2021"
            exit 1
            ;;
    esac
}

# Check if terraform.tfvars exists
check_tfvars() {
    if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        echo -e "${YELLOW}terraform.tfvars not found. Creating from example...${NC}"

        # Generate a random password
        RANDOM_PASSWORD=$(openssl rand -base64 12)

        cat > "$TERRAFORM_DIR/terraform.tfvars" << EOF
admin_username = "exceladmin"
admin_password = "${RANDOM_PASSWORD}!"
excel_version  = "$EXCEL_VERSION"
location       = "$LOCATION"
EOF

        echo -e "${GREEN}Created terraform.tfvars with generated password${NC}"
        echo -e "${YELLOW}Password: ${RANDOM_PASSWORD}!${NC}"
        echo -e "${YELLOW}(Save this password - you'll need it for RDP)${NC}"
    fi
}

# Deploy infrastructure
deploy() {
    echo ""
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    cd "$TERRAFORM_DIR"
    terraform init -upgrade

    echo ""
    echo -e "${YELLOW}Planning deployment...${NC}"
    terraform plan -var="excel_version=$EXCEL_VERSION" -var="location=$LOCATION" -var="vm_size=$VM_SIZE" -var="use_spot_vm=$USE_SPOT" -out=tfplan

    echo ""
    echo -e "${YELLOW}Applying deployment...${NC}"
    terraform apply tfplan

    echo ""
    echo -e "${GREEN}=== Deployment Complete ===${NC}"
    echo ""
    echo -e "${GREEN}VM Details:${NC}"
    terraform output

    echo ""
    echo -e "${YELLOW}=== Next Steps ===${NC}"
    echo "1. Connect via RDP using the public IP above"
    echo "2. Open PowerShell as Administrator on the VM"
    echo "3. Run: C:\\ExcelSetup\\setup.exe /configure C:\\ExcelSetup\\config.xml"
    echo "4. Wait for Excel installation to complete (5-10 minutes)"
    echo "5. Launch Excel and run your tests"
    echo "6. When done, run: ./scripts/destroy.sh"
    echo ""
    echo -e "${RED}IMPORTANT: Remember to destroy the VM when done to avoid charges!${NC}"
}

# Main
check_prerequisites
validate_version
check_tfvars
deploy
