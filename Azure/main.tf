# setup terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id

  features {}
}


# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
  name     = "myResourceGroup"
  location = "westus"

  tags = {
    environment = "Terraform Demo"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = "westus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  tags = {
    environment = "Terraform Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
  name                         = "myPublicIP"
  location                     = "westus"
  resource_group_name          = azurerm_resource_group.myterraformgroup.name
  allocation_method            = "Dynamic"

  tags = {
    environment = "Terraform Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "myNetworkSecurityGroup"
  location            = "westus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_network_security_rule" "myhttprule" {
  name                       = "HTTP"
  direction                  = "Inbound"
  access                     = "Allow"
  priority                   = "1002"
  source_address_prefix      = "*"
  source_port_range          = "*"
  destination_address_prefix = "*"
  destination_port_range     = "1880"
  protocol                   = "Tcp"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  network_security_group_name = azurerm_network_security_group.myterraformnsg.name

}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
  name                      = "myNIC"
  location                  = "westus"
  resource_group_name       = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
  }

  tags = {
    environment = "Terraform Demo"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.myterraformnic.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.myterraformgroup.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                        = "diag${random_id.randomId.hex}"
  resource_group_name         = azurerm_resource_group.myterraformgroup.name
  location                    = "westus"
  account_tier                = "Standard"
  account_replication_type    = "LRS"

  tags = {
    environment = "Terraform Demo"
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" {
  value = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name                  = "myVM"
  location              = "westus"
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.myterraformnic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = "myvm"
  admin_username = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username       = "azureuser"
    public_key     = file("${path.module}/keyfiles/id_rsa.pub")
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform Demo"
  }

  connection {
    host = self.public_ip_address
    user = "azureuser"
    type = "ssh"
    private_key = file("${path.module}/keyfiles/id_rsa")
    timeout = "4m"
    agent = false
  }


  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sleep 5",
      "sudo apt-get install docker.io -y",
      "sudo docker run -d -p 1880:1880 -v node_red_data:/data --name mynodered nodered/node-red:latest"
    ]
  }
}