# Azure Excel Compatibility Lab - Outputs

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vm_name" {
  description = "Name of the VM"
  value       = azurerm_windows_virtual_machine.excel_vm.name
}

output "public_ip" {
  description = "Public IP address of the VM (use for RDP connection)"
  value       = azurerm_public_ip.main.ip_address
}

output "admin_username" {
  description = "Administrator username"
  value       = var.admin_username
}

output "excel_version" {
  description = "Excel version installed on VM"
  value       = var.excel_version
}

output "rdp_connection" {
  description = "RDP connection command"
  value       = "Connect via RDP to ${azurerm_public_ip.main.ip_address}:3389 with username '${var.admin_username}'"
}

output "vm_id" {
  description = "Azure resource ID of the VM"
  value       = azurerm_windows_virtual_machine.excel_vm.id
}

output "spot_vm_enabled" {
  description = "Whether Spot VM pricing is enabled"
  value       = var.use_spot_vm
}
