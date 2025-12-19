terraform {

  required_providers {
    azapi = {
      source  = "azure/azapi"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "3ab97c04-ca68-41d4-8b83-2b9cf0723c23"
}

resource "random_id" "random_id" {
  byte_length = 2
}

#########################
# Resource Group & Netzwerk
#########################
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg-${random_id.random_id.hex}"
  location = "${var.azure-location}"
  tags = {
    source = var.tag_source_git
    owner  = var.tag_owner
    host   = var.tag_source_host
    create = local.today-timestamp
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "f5-vnet"
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
  name                = "f5-nic-mgmt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig-mgmt"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mgmt_ip.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "188.61.92.176/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-8443"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 8443
    source_address_prefix      = "188.61.92.176/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-80"
    priority                   = 1101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*" 
    destination_port_range     = 80
    source_address_prefix      = "188.61.92.176/32" 
    destination_address_prefix = "*" 
  }

}

resource "azurerm_network_interface_security_group_association" "nisga" {
  network_interface_id    = azurerm_network_interface.nic_mgmt.id
  network_security_group_id = azurerm_network_security_group.nsg.id
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

  # SSH Key aktivieren
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  disable_password_authentication = true

  source_image_reference {
    publisher = "f5-networks"
    offer     = "f5-big-ip-byol"
    sku       = "f5-big-all-2slot-byol"
    version   = "17.5.103241"
  }

  plan {
    name      = "f5-big-all-2slot-byol"
    product   = "f5-big-ip-byol"
    publisher = "f5-networks"
}

  os_disk {
    name                 = "f5-bigip-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(local.cloudinit)

  tags = {
    environment = "demo"
  }
}
