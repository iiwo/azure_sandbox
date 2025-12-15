# Project Progress

## Current Status: Fully Operational

### Completed
- [x] Project structure created
- [x] Documentation (README.md, PROGRESS.md)
- [x] ODT configuration files for Excel 2016/2019/2021
- [x] Terraform configuration for Azure infrastructure
- [x] VM provisioning scripts (deploy.sh, destroy.sh, status.sh)
- [x] Excel installation PowerShell script
- [x] Azure CLI installed and authenticated
- [x] First successful VM deployment (Excel 2016)

### Verified Working
- [x] Azure Spot VM provisioning (Standard_D2s_v3)
- [x] Windows 11 Pro (24H2) image
- [x] Auto-shutdown scheduling
- [x] Office Deployment Tool auto-download
- [x] RDP connectivity

---

## Project Structure

```
azure_sandbox/
├── CLAUDE.md              # Project instructions
├── README.md              # Usage documentation
├── PROGRESS.md            # This file
├── .gitignore             # Git ignore rules
├── doc/
│   └── Plan.md            # Detailed implementation plan
├── terraform/
│   ├── main.tf            # Main Azure infrastructure
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   └── terraform.tfvars.example
├── odt-configs/
│   ├── excel2016.xml      # Excel 2016 ODT config
│   ├── excel2019.xml      # Excel 2019 ODT config
│   └── excel2021.xml      # Excel 2021 ODT config
└── scripts/
    ├── deploy.sh          # Deploy VM script
    ├── destroy.sh         # Destroy resources script
    ├── status.sh          # Check deployment status
    └── install-excel.ps1  # PowerShell Excel installer
```

## Implementation Log

### 2024-12-13 - Initial Implementation & First Deployment

**Created:**
- Project directory structure
- README.md with comprehensive usage instructions
- PROGRESS.md for tracking
- ODT configuration files for Excel 2016, 2019, 2021
- Terraform configuration
- Shell scripts for deployment lifecycle
- PowerShell script for manual Excel installation

**Issues Resolved:**
- Windows computer name max 15 chars - added explicit `computer_name`
- Windows 11 image SKU updated from `win11-22h2-pro` to `win11-24h2-pro`
- VM size changed from `Standard_B2s` to `Standard_D2s_v3` for better Spot availability

**First Successful Deployment:**
- Region: westus2
- VM: excel-test-vm-hiwjji
- Public IP: 20.3.171.107
- Excel Version: 2016
- Status: Running (Spot VM)

---

## Quick Reference

### Deploy a Test VM
```bash
./scripts/deploy.sh 2016        # Excel 2016
./scripts/deploy.sh 2019        # Excel 2019
./scripts/deploy.sh 2021        # Excel 2021
./scripts/deploy.sh 2019 eastus # Specific region
```

### On the VM (PowerShell as Admin)
```powershell
# Install Excel
C:\ExcelSetup\setup.exe /configure C:\ExcelSetup\config.xml
```

### Destroy Resources
```bash
./scripts/destroy.sh
```

### Check Status
```bash
./scripts/status.sh
```

---

## Cost Summary

| Component | Estimated Cost |
|-----------|---------------|
| Spot VM (Standard_D2s_v3) | ~$0.02-0.04/hour |
| Storage (128GB SSD) | ~$0.05/hour |
| Network egress | Minimal |
| **Total per test session** | **< $1 for 1-2 hours** |

---

## Notes

- Spot VMs may be evicted by Azure - this is expected
- Excel runs in evaluation mode (~30 day grace period)
- Auto-shutdown set to 7 PM UTC to prevent runaway costs
- Always run `./scripts/destroy.sh` after testing
