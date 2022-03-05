# setup terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "<=2.0.0"
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


# Create a resource group for core
resource "azurerm_resource_group" "core-rg" {
  name     = "MC4615-vFW-core-rg"
  location = "eastus2"
  tags = {
    business_owner   = "mc4615"
    environment      = "Core"
    application_name = "vFW_demo_app"
  }
}

# Create the core VNET
resource "azurerm_virtual_network" "core-vnet" {
  name                = "MC4615-vFW-core-vnet"
  address_space       = ["10.10.0.0/16"]
  resource_group_name = azurerm_resource_group.core-rg.name
  location            = azurerm_resource_group.core-rg.location
  tags = {
    environment = "Core"
  }
}

# Create a subnet for Azure Firewall
# Note: The Subnet used for the Firewall must have the mandatory name AzureFirewallSubnet 
# and requires at least a /26 subnet size.
resource "azurerm_subnet" "AzureFirewallSubnet" {
  name                 = "AzureFirewallSubnet" # mandatory name -do not rename-
  address_prefix       = "10.10.1.0/26"
  virtual_network_name = azurerm_virtual_network.core-vnet.name
  resource_group_name  = azurerm_resource_group.core-rg.name
}

# Create the public ip for Azure Firewall
resource "azurerm_public_ip" "azure_firewall_pip" {
  name                = "MC4615-vFW-core-azure-firewall-pip"
  resource_group_name = azurerm_resource_group.core-rg.name
  location            = azurerm_resource_group.core-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = "Core"
  }
}

# Create the Azure Firewall
resource "azurerm_firewall" "azure_firewall" {
  depends_on          = [azurerm_public_ip.azure_firewall_pip]
  name                = "MC4615-vFW-core-azure-firewall"
  resource_group_name = azurerm_resource_group.core-rg.name
  location            = azurerm_resource_group.core-rg.location
  ip_configuration {
    name                 = "hg-eastus2-core-azure-firewall-config"
    subnet_id            = azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.azure_firewall_pip.id
  }

  tags = {
    environment = "Core"
  }
}

# create some rules for the firewall
# 1. Create a Azure Firewall Network Rule for DNS
# Resolve DNS queries using Google Public DNS IP addresses
resource "azurerm_firewall_network_rule_collection" "fw-net-dns" {
  name                = "MC4615-vFW-azure-firewall-dns-rule"
  azure_firewall_name = azurerm_firewall.azure_firewall.name
  resource_group_name = azurerm_resource_group.core-rg.name
  priority            = 100
  action              = "Allow"
  rule {
    name                  = "DNS"
    source_addresses      = ["10.0.0.0/16"]
    destination_ports     = ["53"]
    destination_addresses = ["8.8.8.8", "8.8.4.4"]
    protocols             = ["TCP", "UDP"]
  }
}

# 2. Create a Azure Firewall Network Rule for Web access
# Access websites using HTTP and HTTPS protocols
resource "azurerm_firewall_network_rule_collection" "fw-net-web" {
  name                = "MC4615-vFW-azure-firewall-web-rule"
  azure_firewall_name = azurerm_firewall.azure_firewall.name
  resource_group_name = azurerm_resource_group.core-rg.name
  priority            = 101
  action              = "Allow"
  rule {
    name                  = "HTTP"
    source_addresses      = ["10.0.0.0/16"]
    destination_ports     = ["80"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }
  rule {
    name                  = "HTTPS"
    source_addresses      = ["10.0.0.0/16"]
    destination_ports     = ["443"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }
}

# 3. Create a Azure Firewall Network Rule for Azure Active Directoy
# Azure Firewall blocks Active Directory access by default
resource "azurerm_firewall_network_rule_collection" "fw-net-azure-ad" {
  name                = "MC4615-vFW-azure-firewall-azure-ad-rule"
  azure_firewall_name = azurerm_firewall.azure_firewall.name
  resource_group_name = azurerm_resource_group.core-rg.name
  priority            = 104
  action              = "Allow"
  rule {
    name                  = "Azure-AD"
    source_addresses      = ["10.0.0.0/16"]
    destination_ports     = ["25"]
    destination_addresses = ["AzureActiveDirectory"]
    protocols             = ["TCP", "UDP"]
  }
}
