output "resource_group_id" {
  description = "Existing resource group ID."
  value       = data.azurerm_resource_group.app.id
}

output "aks_cluster_id" {
  description = "Existing AKS cluster ID."
  value       = data.azurerm_kubernetes_cluster.app.id
}

output "acr_login_server" {
  description = "Existing ACR login server."
  value       = data.azurerm_container_registry.app.login_server
}

output "postgresql_fqdn" {
  description = "Existing PostgreSQL Flexible Server FQDN."
  value       = data.azurerm_postgresql_flexible_server.app.fqdn
}

output "storage_account_primary_blob_endpoint" {
  description = "Existing storage account primary Blob endpoint."
  value       = data.azurerm_storage_account.app.primary_blob_endpoint
}

output "key_vault_uri" {
  description = "Existing Key Vault URI."
  value       = data.azurerm_key_vault.app.vault_uri
}
