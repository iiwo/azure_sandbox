# Azure Excel Compatibility Lab - Variables

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "excel-compat-lab-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "vm_name" {
  description = "Name of the Windows VM"
  type        = string
  default     = "excel-test-vm"
}

variable "vm_size" {
  description = "Size of the VM. Alternatives if unavailable: Standard_D2s_v5, Standard_D2as_v5, Standard_B2ms"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Administrator username for the VM"
  type        = string
  default     = "exceladmin"
}

variable "admin_password" {
  description = "Administrator password for the VM"
  type        = string
  sensitive   = true
}

variable "excel_version" {
  description = "Excel version to install (2016, 2019, or 2021)"
  type        = string
  default     = "2019"
  validation {
    condition     = contains(["2016", "2019", "2021"], var.excel_version)
    error_message = "Excel version must be 2016, 2019, or 2021."
  }
}

variable "use_spot_vm" {
  description = "Use Azure Spot VM for cost savings (can be evicted)"
  type        = bool
  default     = true
}

variable "auto_shutdown_time" {
  description = "Auto-shutdown time in HH:MM format (24-hour, UTC)"
  type        = string
  default     = "2300"  # 11 PM UTC
}

variable "auto_shutdown_enabled" {
  description = "Enable auto-shutdown for the VM"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Testing"
    Project     = "Excel-Compatibility-Lab"
    Disposable  = "true"
  }
}
