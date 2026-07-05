data "azurerm_resource_group" "app" {
  name = var.resource_group_name
}

data "azurerm_kubernetes_cluster" "app" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

data "azurerm_container_registry" "app" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
}

data "azurerm_postgresql_flexible_server" "app" {
  name                = var.postgresql_server_name
  resource_group_name = var.resource_group_name
}

data "azurerm_storage_account" "app" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault" "app" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}
