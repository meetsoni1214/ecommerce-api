resource "azurerm_key_vault" "app" {
  name                = var.key_vault_name
  location            = data.azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  tenant_id           = var.tenant_id

  sku_name = "standard"

  tags = local.common_tags
}
