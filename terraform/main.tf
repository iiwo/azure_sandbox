# Azure Excel Compatibility Lab - Main Configuration
# Creates a disposable Windows VM with Excel for compatibility testing

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_group_name}-${random_string.suffix.result}"
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "excel-lab-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "excel-lab-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "excel-lab-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "excel-lab-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # Allow RDP
  security_rule {
    name                       = "AllowRDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "excel-lab-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "excel_vm" {
  name                = "${var.vm_name}-${random_string.suffix.result}"
  computer_name       = "excel${random_string.suffix.result}"  # Max 15 chars for Windows
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  # Spot VM configuration for cost savings
  priority        = var.use_spot_vm ? "Spot" : "Regular"
  eviction_policy = var.use_spot_vm ? "Delete" : null
  max_bid_price   = var.use_spot_vm ? -1 : null  # -1 means up to on-demand price

  network_interface_ids = [
    azurerm_network_interface.main.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  # Windows 11 Pro image
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-pro"
    version   = "latest"
  }

  # Enable WinRM for remote management
  winrm_listener {
    protocol = "Http"
  }

  # Custom script extension to download ODT and prepare for Excel installation
  # The actual Excel installation will be done manually or via separate script
  # to allow for flexible version selection
}

# Auto-shutdown schedule
resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto_shutdown" {
  count              = var.auto_shutdown_enabled ? 1 : 0
  virtual_machine_id = azurerm_windows_virtual_machine.excel_vm.id
  location           = azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = var.tags
}

# Local values for Excel configuration
locals {
  excel_configs = {
    "2016" = {
      channel    = "PerpetualVL2016"
      product_id = "ProPlusVolume"
      edition    = "32"
    }
    "2019" = {
      channel    = "PerpetualVL2019"
      product_id = "ProPlus2019Volume"
      edition    = "64"
    }
    "2021" = {
      channel    = "PerpetualVL2021"
      product_id = "ProPlus2021Volume"
      edition    = "64"
    }
  }
  selected_config = local.excel_configs[var.excel_version]
}

# Custom Script Extension to prepare the VM
resource "azurerm_virtual_machine_extension" "prepare_vm" {
  name                 = "prepare-excel-vm"
  virtual_machine_id   = azurerm_windows_virtual_machine.excel_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"New-Item -ItemType Directory -Force -Path C:\\ExcelSetup; $odtUrl = 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_17830-20162.exe'; Invoke-WebRequest -Uri $odtUrl -OutFile C:\\ExcelSetup\\odt.exe; Start-Process -FilePath C:\\ExcelSetup\\odt.exe -ArgumentList '/quiet /extract:C:\\ExcelSetup' -Wait; $configXml = '<Configuration><Add OfficeClientEdition=''${local.selected_config.edition}'' Channel=''${local.selected_config.channel}''><Product ID=''${local.selected_config.product_id}''><Language ID=''en-us'' /><ExcludeApp ID=''Access'' /><ExcludeApp ID=''Groove'' /><ExcludeApp ID=''Lync'' /><ExcludeApp ID=''OneDrive'' /><ExcludeApp ID=''OneNote'' /><ExcludeApp ID=''Outlook'' /><ExcludeApp ID=''PowerPoint'' /><ExcludeApp ID=''Publisher'' /><ExcludeApp ID=''Teams'' /><ExcludeApp ID=''Word'' /></Product></Add><Updates Enabled=''FALSE'' /><Display Level=''Full'' AcceptEULA=''TRUE'' /><Property Name=''AUTOACTIVATE'' Value=''0'' /><Property Name=''FORCEAPPSHUTDOWN'' Value=''TRUE'' /></Configuration>'; $configXml | Out-File -FilePath C:\\ExcelSetup\\config.xml -Encoding UTF8; 'Excel ${var.excel_version} setup ready. Run: C:\\ExcelSetup\\setup.exe /configure C:\\ExcelSetup\\config.xml' | Out-File C:\\ExcelSetup\\readme.txt\""
  })

  tags = var.tags

  depends_on = [azurerm_windows_virtual_machine.excel_vm]
}
