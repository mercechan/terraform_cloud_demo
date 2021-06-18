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

resource "azurerm_resource_group" "terraform_cloud_rg" {
  name = var.rg_name
  location = var.location
  tags = {
    business_owner = "merce.chan"
    cost_centre = "12345"
    application_name = "terraform_cloud_azure_demo"
  }
}