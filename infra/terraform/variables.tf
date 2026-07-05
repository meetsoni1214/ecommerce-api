variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the existing learning resources."
  type        = string
}

variable "aks_cluster_name" {
  description = "Existing AKS cluster name."
  type        = string
}

variable "acr_name" {
  description = "Existing Azure Container Registry name."
  type        = string
}

variable "postgresql_server_name" {
  description = "Existing Azure Database for PostgreSQL Flexible Server name."
  type        = string
}

variable "storage_account_name" {
  description = "Existing Azure Storage account name."
  type        = string
}

variable "key_vault_name" {
  description = "Existing Azure Key Vault name."
  type        = string
}
