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
│   ├── status.sh       # Check deployment status
│   └── install-excel.ps1  # PowerShell script for Excel installation
└── doc/
    └── Plan.md         # Detailed implementation plan
```

## Quick Start

### 1. Deploy a Test VM

```bash
# Deploy VM with Excel 2019 (default)
./scripts/deploy.sh

# Or deploy with a specific Excel version
./scripts/deploy.sh 2016
./scripts/deploy.sh 2021

# You can also specify the Azure region (default: eastus)
./scripts/deploy.sh 2019 westus
```

The deploy script will:
- Check prerequisites (Azure CLI, Terraform)
- Prompt for Azure login if needed
- Generate a random admin password (saved to terraform.tfvars)
- Deploy the VM and show connection details

### 2. Check Status

```bash
# View current deployment status and connection info
./scripts/status.sh
```

### 3. Connect and Test

Connect via RDP using the public IP shown in the deployment output. The script will display credentials and next steps for installing Excel on the VM.

### 4. Clean Up (IMPORTANT!)

```bash
# Destroy all resources when done
./scripts/destroy.sh
```

This will prompt for confirmation and optionally clean up local Terraform files.

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
