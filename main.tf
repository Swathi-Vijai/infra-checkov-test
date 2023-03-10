# resource "azurerm_resource_group" "appgrp" {
#   name     = local.resource_group_name
#   location = local.location  
# }
# old
# terraform {
#   required_providers {
#     azurerm = {
#       source = "hashicorp/azurerm"
#       version = "3.30.0"
#     }
#   }
# }

# provider "azurerm" {
#   features {}
#   skip_provider_registration = true
# }

# locals {
#   resource_group_name = "Devops-RG"
#   location = "East US"

# }

# resource "azurerm_resource_group" "rg" {
#   name     = local.resource_group_name
#   location = local.location
# }


# resource "azurerm_virtual_network" "sai-network" {
#   name                = "sai-network"
#   location            = local.location
#   resource_group_name = local.resource_group_name
#   address_space       = ["10.0.0.0/16"]
#   dns_servers         = ["10.0.0.4", "10.0.0.5"]
#   depends_on = [
#     azurerm_resource_group.rg
#   ]
# }

# resource "azurerm_subnet" "SubnetA" {
#   name                 = "SubnetA"
#   resource_group_name  = local.resource_group_name
#   virtual_network_name = azurerm_virtual_network.sai-network.name
#   address_prefixes     = ["10.0.1.0/24"]
#   depends_on = [
#     azurerm_virtual_network.sai-network
#   ]
# }

# resource "azurerm_network_interface" "interface" {
#   name                = "sai-interface"
#   location            = local.location
#   resource_group_name = local.resource_group_name

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.SubnetA.id
#     private_ip_address_allocation = "Dynamic"
#     #public_ip_address_id = azurerm_public_ip.ip.id
#   }
#   depends_on = [
#     azurerm_subnet.SubnetA
#   ]
# }
# resource "azurerm_windows_virtual_machine" "sai-vm" {
#   name                = "sai-vm"
#   resource_group_name = local.resource_group_name
#   location            = local.location
#   size                = "Standard_D2s_v3"
#   allow_extension_operations = false
#   admin_username      = "sai-ch"
#   admin_password      = "Azuresai@123"
#   network_interface_ids = [
#     azurerm_network_interface.interface.id,
#   ]

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "MicrosoftWindowsServer"
#     offer     = "WindowsServer"
#     sku       = "2019-Datacenter"
#     version   = "latest"
#   }
#   depends_on = [
#     azurerm_resource_group.rg,
#     azurerm_network_interface.interface,
#   ]
# }
# old

/*
# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY AN ADVANCED AZURE VIRTUAL MACHINE
# This is an advanced example of how to deploy an Azure Virtual Machine in an availability set, managed disk 
# and networking with a public IP.
# ---------------------------------------------------------------------------------------------------------------------
# See test/azure/terraform_azure_vm_example_test.go for how to write automated tests for this code.
# ---------------------------------------------------------------------------------------------------------------------

provider "azurerm" {
  version = "~> 2.50"
  features {}
}

# ---------------------------------------------------------------------------------------------------------------------
# PIN TERRAFORM VERSION
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.12.26"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A RESOURCE GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_resource_group" "vm_rg" {
  name     = "terratest-vm-rg-${var.postfix}"
  location = var.location
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY NETWORK RESOURCES
# This network includes a public address for integration test demonstration purposes
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.postfix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${var.postfix}"
  resource_group_name  = azurerm_resource_group.vm_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_public_ip" "pip" {
  name                    = "pip-${var.postfix}"
  resource_group_name     = azurerm_resource_group.vm_rg.name
  location                = azurerm_resource_group.vm_rg.location
  allocation_method       = "Static"
  ip_version              = "IPv4"
  sku                     = "Standard"
  idle_timeout_in_minutes = "4"
}

# Public and Private IPs assigned to one NIC for test demonstration purposes
resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.postfix}"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "terratestconfiguration1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY AN AVAILABILITY SET
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_availability_set" "avs" {
  name                        = "avs-${var.postfix}"
  location                    = azurerm_resource_group.vm_rg.location
  resource_group_name         = azurerm_resource_group.vm_rg.name
  platform_fault_domain_count = 2
  managed                     = true
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY VIRTUAL MACHINE
# This VM does not actually do anything and is the smallest size VM available with a Windows image
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine" "vm_example" {
  name                             = "vm-${var.postfix}"
  location                         = azurerm_resource_group.vm_rg.location
  resource_group_name              = azurerm_resource_group.vm_rg.name
  network_interface_ids            = [azurerm_network_interface.nic.id]
  availability_set_id              = azurerm_availability_set.avs.id
  vm_size                          = var.vm_size
  license_type                     = var.vm_license_type
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }

  storage_os_disk {
    name              = "osdisk-${var.postfix}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.disk_type
  }

  os_profile {
    computer_name  = "vm-${var.postfix}"
    admin_username = var.user_name
    admin_password = Swathi493
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  tags = {
    "Version"     = "0.0.1"
    "Environment" = "dev"
  }

  depends_on = [random_password.rand]
}

# Random password is used as an example to simplify the deployment and improve the security of the remote VM.
# This is not as a production recommendation as the password is stored in the Terraform state file.
resource "random_password" "rand" {
  length           = 16
  override_special = "-_%@"
  min_upper        = "1"
  min_lower        = "1"
  min_numeric      = "1"
  min_special      = "1"
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH A MANAGED DISK TO THE VIRTUAL MACHINE
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_managed_disk" "disk" {
  name                 = "disk-${var.postfix}"
  location             = azurerm_resource_group.vm_rg.location
  resource_group_name  = azurerm_resource_group.vm_rg.name
  storage_account_type = var.disk_type
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm_disk" {
  managed_disk_id    = azurerm_managed_disk.disk.id
  virtual_machine_id = azurerm_virtual_machine.vm_example.id
  caching            = "ReadWrite"
  lun                = 10
}
*/




