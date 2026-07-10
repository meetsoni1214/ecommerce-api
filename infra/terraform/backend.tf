terraform {
  backend "azurerm" {
    resource_group_name  = "learn-aks"
    storage_account_name = "learnaksbs"
    container_name       = "tfstate"
    key                  = "ecommerce-api/terraform.tfstate"
    use_azuread_auth     = true
  }
}
