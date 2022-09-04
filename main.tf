#Define the terraform provider (Azure in this case)
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.96.0"
    }
  }
}


#Configure the terraform provider
provider "azurerm" {
  features {}


}

# Create a resource group
resource "azurerm_resource_group" "rgp" {
  name     = var.resource_group_name
  location = var.azure_location
}

# Create a virtual network 
resource "azurerm_virtual_network" "vnet" {
  name                = var.network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rgp.location
  resource_group_name = azurerm_resource_group.rgp.name
}

# Create a subnet for the virtual network
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rgp.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create a Public IP
resource "azurerm_public_ip" "publicip" {
    count = length(var.public_ip)
    name                         = var.public_ip[count.index]
    location                     = azurerm_resource_group.rgp.location
    resource_group_name          = azurerm_resource_group.rgp.name
    allocation_method            = "Dynamic"
}

# Create a network interface card for the linux VMs
resource "azurerm_network_interface" "nic" {
    count= length(var.network_card)
  name                = var.network_card[count.index]
  location            = azurerm_resource_group.rgp.location
  resource_group_name = azurerm_resource_group.rgp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.publicip[count.index].id
    
  }
}


# Create a network security group rule
resource "azurerm_network_security_group" "nsg" {
    name                = var.network_security_group
    location            = azurerm_resource_group.rgp.location
    resource_group_name = azurerm_resource_group.rgp.name

    security_rule {
        name                       = "SSH"
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsgconnection" {
    count = length(azurerm_network_interface.nic.*.id)
    network_interface_id      = element(azurerm_network_interface.nic.*.id, count.index)
    network_security_group_id = azurerm_network_security_group.nsg.id
}


# Create (and display) an SSH key
resource "tls_private_key" "devops" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.devops.private_key_pem 
    sensitive = true
}

resource "local_file" "devopskey" {
  filename = "devops.pem"
  content = tls_private_key.devops.private_key_pem
}

# Create Centos Linux VMs 
resource "azurerm_linux_virtual_machine" "vm1" {
    count = length(var.vm_name)
  name                = var.vm_name[count.index]
  resource_group_name = azurerm_resource_group.rgp.name
  location            = azurerm_resource_group.rgp.location
  size                = "Standard_B2s"
  admin_username      = "devops"
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  admin_ssh_key {
    username   = "devops"
    public_key = tls_private_key.devops.public_key_openssh
  }


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "79-gen2"
    version   = "latest"
  }



  tags = {
    gluster = "vm1"
}

}

#To get the corresponding private key, run "terraform output -raw tls_private_key"
