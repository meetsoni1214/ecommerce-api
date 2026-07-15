resource "azurerm_user_assigned_identity" "github_publisher" {
  name                = "ecommerce-api-github-publisher"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name

  tags = local.common_tags
}

resource "azurerm_federated_identity_credential" "github_publisher" {
  name                      = "github-main"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_publisher.id
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${var.github_repository}:ref:refs/heads/main"
  audience                  = ["api://AzureADTokenExchange"]
}

resource "azurerm_role_assignment" "github_publisher_acr_push" {
  scope                            = azurerm_container_registry.app.id
  role_definition_name             = "AcrPush"
  principal_id                     = azurerm_user_assigned_identity.github_publisher.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_user_assigned_identity" "github_deployer" {
  name                = "ecommerce-api-github-deployer"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name

  tags = local.common_tags
}

resource "azurerm_federated_identity_credential" "github_deployer" {
  name                      = "github-${var.github_environment}"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_deployer.id
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${var.github_repository}:environment:${var.github_environment}"
  audience                  = ["api://AzureADTokenExchange"]
}

resource "azurerm_role_assignment" "github_deployer_aks_user" {
  scope                            = azurerm_kubernetes_cluster.app.id
  role_definition_name             = "Azure Kubernetes Service Cluster User Role"
  principal_id                     = azurerm_user_assigned_identity.github_deployer.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
