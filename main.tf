terraform {

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#########################
# Variablen (Passe hier an)
#########################
variable "f5_license_key" {
  description = "Dein F5 BYOL Lizenzschlüssel"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Admin Passwort für BIG-IP"
  type        = string
  default     = "P@ssw0rd1234!"
}

#########################
# Resource Group & Netzwerk
#########################
resource "azurerm_resource_group" "rg" {
  name     = "rg-f5-bigip"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-f5"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "mgmt" {
  name                 = "subnet-mgmt"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "mgmt_ip" {
  name                = "f5-mgmt-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic_mgmt" {
  name                = "nic-mgmt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig-mgmt"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mgmt_ip.id
  }
}

#########################
# Cloud-Init Script (User Data)
#########################
data "template_file" "cloudinit" {
  template = <<-EOT
    #cloud-config
    write_files:
      - path: /config/startup-license.sh
        permissions: '0755'
        content: |
          #!/bin/bash
          echo "Starte automatische Lizenzaktivierung..."
          tmsh modify sys global-settings gui-setup disabled
          tmsh modify sys httpd ssl-port 443
          tmsh modify sys ntp servers add { 0.pool.ntp.org 1.pool.ntp.org }
          tmsh modify sys dns name-servers add { 8.8.8.8 1.1.1.1 }
          tmsh save sys config
          tmsh install sys license registration-key ${"f5_license_key"}
          tmsh save sys config
          echo "BIG-IP Lizenz aktiviert."
    runcmd:
      - [ bash, /config/startup-license.sh ]
  EOT

  vars = {
    f5_license_key = var.f5_license_key
  }
}

#########################
# Virtual Machine (F5 BIG-IP BYOL)
#########################
resource "azurerm_linux_virtual_machine" "bigip" {
  name                = "f5-bigip-byol"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_D3_v2"
  admin_username      = "adminuser"
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.nic_mgmt.id
  ]

  source_image_reference {
    publisher = "f5-networks"
    offer     = "f5-big-ip-byol"
    sku       = "f5-big-all-1slot-byol"
    version   = "latest"
  }

  os_disk {
    name                 = "f5-bigip-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(data.template_file.cloudinit.rendered)

  tags = {
    environment = "demo"
  }
}
