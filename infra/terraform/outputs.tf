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

output "github_actions_publisher_client_id" {
  description = "Client ID used by GitHub Actions to publish images to ACR."
  value       = azurerm_user_assigned_identity.github_publisher.client_id
}

output "github_actions_deployer_client_id" {
  description = "Client ID used by the approved GitHub production deployment."
  value       = azurerm_user_assigned_identity.github_deployer.client_id
}
