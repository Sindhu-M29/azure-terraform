terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.88.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "f231ecf7-d2da-4999-9062-528f2ceeaa1f"
  client_id       = "5b051ab0-10bc-43a5-9df8-cf89d32642d7"
  tenant_id       = "66fca911-a422-4197-b03e-8057ca45313c"
}


resource "azurerm_resource_group" "RG" {
  name     = "RG1-Terraform"
  location = "Central India"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "terraform-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "pub-subnet-1"
  address_prefixes    = ["10.0.2.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.RG.name
}

resource "azurerm_network_interface" "nic" {
  name                = "terraform-nic"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = "pub-subnet-1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
  }

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_network_security_group" "NSG" {
  name                = "Terraform-nsg"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.NSG.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "terraform-VM2"
  resource_group_name   = azurerm_resource_group.RG.name
  location              = azurerm_resource_group.RG.location
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_F2"
   
  admin_username        = "azureuser"
  admin_password        ="Azuresind@29"
  disable_password_authentication = false
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
      offer   = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"

    version   = "latest"
  }

  depends_on = [azurerm_network_interface.nic]
    

 
  }

