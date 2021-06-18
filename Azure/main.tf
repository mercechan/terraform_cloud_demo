provider "azurerm" {
  version = "<=2.0.0"
  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
  features {}
}

resource "azurerm_resource_group" "terraform_cloud_rg" {
  name = var.rg_name
  location = var.location
}