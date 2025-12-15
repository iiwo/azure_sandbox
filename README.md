# Azure Excel Compatibility Lab

A disposable Azure-based testing environment for Excel 2016/2019/2021 compatibility testing. Uses Azure Spot VMs with unactivated Excel installations for cost-efficient, ephemeral testing.

## Overview

This project provides infrastructure-as-code and scripts to:
- Spin up Windows VMs on Azure Spot instances (up to 90% cheaper)
- Install specific Excel versions (2016, 2019, 2021) via Office Deployment Tool
- Run compatibility tests in evaluation mode (no license required)
- Automatically clean up resources after testing

## Prerequisites

- Azure account with active subscription (free trial works)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- [Terraform](https://www.terraform.io/downloads) installed
- RDP client for connecting to Windows VMs

## Project Structure

```
azure_sandbox/
├── terraform/           # Azure infrastructure as code
│   ├── main.tf         # Main Terraform configuration
│   ├── variables.tf    # Input variables
│   ├── outputs.tf      # Output values
│   └── terraform.tfvars.example
├── odt-configs/         # Office Deployment Tool configurations
│   ├── excel2016.xml   # Excel 2016 configuration
│   ├── excel2019.xml   # Excel 2019 configuration
│   └── excel2021.xml   # Excel 2021 configuration
├── scripts/             # Helper scripts
│   ├── deploy.sh       # Deploy VM script
│   ├── destroy.sh      # Destroy VM script
│   └── install-excel.ps1  # PowerShell script for Excel installation
└── doc/
    └── Plan.md         # Detailed implementation plan
```

## Quick Start

### 1. Azure Setup

```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "Your Subscription Name"
```

### 2. Deploy a Test VM

```bash
# Initialize Terraform
cd terraform
terraform init

# Deploy VM with Excel 2019 (default)
terraform apply -var="excel_version=2019"

# Or deploy with different Excel version
terraform apply -var="excel_version=2016"
terraform apply -var="excel_version=2021"
```

### 3. Connect and Test

```bash
# Get the VM's public IP
terraform output public_ip

# Connect via RDP using the IP address
# Default credentials are in terraform outputs
```

### 4. Clean Up (IMPORTANT!)

```bash
# Always destroy the VM after testing to avoid charges
terraform destroy
```

## Excel Versions

| Version | Channel | Notes |
|---------|---------|-------|
| Excel 2016 | PerpetualVL2016 | Volume License, 32-bit |
| Excel 2019 | PerpetualVL2019 | Volume License, 64-bit |
| Excel 2021 | PerpetualVL2021 | Volume License, 64-bit |

## Cost Considerations

- **Spot VMs**: Up to 90% cheaper than regular VMs
- **Pay-per-minute**: Only charged for active compute time
- **Auto-shutdown**: VMs configured to auto-shutdown after 2 hours
- **No license costs**: Using evaluation mode within grace period

## Important Notes

1. **Always delete VMs after testing** - This is critical to avoid ongoing charges
2. **Excel runs in evaluation mode** - Fully functional for ~30 days without activation
3. **Spot VMs can be evicted** - Azure may reclaim the VM at any time (data is deleted)
4. **No persistent data** - Save test results externally before destroying VM

## Troubleshooting

### Spot VM Eviction
If Azure evicts your Spot VM, simply create a new one. This is expected behavior.

### Excel Installation Fails
Ensure the VM has internet access and the ODT configuration is correct.

### RDP Connection Issues
Check that port 3389 is allowed in the Network Security Group.

## License

This project is for testing purposes only. Excel is used in evaluation mode per Microsoft's trial terms.
