#!/bin/bash
# Azure Excel Compatibility Lab - Check VM Availability
# Checks which VM sizes are available in different regions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default VM sizes to check (x86 compatible with Windows)
VM_SIZES=("Standard_D2s_v3" "Standard_D2s_v4" "Standard_D2s_v5" "Standard_D2as_v5" "Standard_B2ms" "Standard_D2s_v6")

# Regions to check
REGIONS=("eastus" "eastus2" "westus2" "westus3" "centralus" "northcentralus" "southcentralus" "canadacentral" "northeurope" "westeurope" "uksouth")

echo -e "${BLUE}=== Azure VM Availability Checker ===${NC}"
echo ""

# Check Azure login
if ! az account show &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Azure. Run 'az login' first.${NC}"
    exit 1
fi

# Check specific region if provided
if [ -n "$1" ]; then
    REGIONS=("$1")
    echo -e "Checking region: ${GREEN}$1${NC}"
else
    echo -e "Checking ${#REGIONS[@]} regions for available VM sizes..."
fi
echo ""

# Function to check if a VM size is available in a region
check_availability() {
    local region=$1
    local size=$2

    # Get restrictions for this SKU
    local result=$(az vm list-skus --location "$region" --size "$size" --resource-type virtualMachines --query "[?name=='$size'].restrictions" -o tsv 2>/dev/null)

    if [ -z "$result" ]; then
        echo "unavailable"
    elif [ "$result" == "[]" ] || [ -z "$(echo "$result" | tr -d '[:space:]')" ]; then
        echo "available"
    else
        echo "restricted"
    fi
}

# Print header
printf "%-20s" "Region"
for size in "${VM_SIZES[@]}"; do
    # Shorten size name for display
    short_name=$(echo "$size" | sed 's/Standard_//')
    printf "%-12s" "$short_name"
done
echo ""
printf '%.0s-' {1..90}
echo ""

# Check each region
for region in "${REGIONS[@]}"; do
    printf "%-20s" "$region"

    for size in "${VM_SIZES[@]}"; do
        status=$(check_availability "$region" "$size")

        case $status in
            "available")
                printf "${GREEN}%-12s${NC}" "✓"
                ;;
            "restricted")
                printf "${YELLOW}%-12s${NC}" "limited"
                ;;
            *)
                printf "${RED}%-12s${NC}" "✗"
                ;;
        esac
    done
    echo ""
done

echo ""
echo -e "${BLUE}Legend:${NC}"
echo -e "  ${GREEN}✓${NC}        = Available"
echo -e "  ${YELLOW}limited${NC}  = Has restrictions (may work)"
echo -e "  ${RED}✗${NC}        = Not available"
echo ""
echo -e "${YELLOW}Usage:${NC} ./scripts/deploy.sh <excel_version> <region> <vm_size>"
echo -e "${YELLOW}Example:${NC} ./scripts/deploy.sh 2019 centralus Standard_D2s_v3"