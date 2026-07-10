resource "azurerm_resource_group" "app" {
  name     = var.resource_group_name
  location = data.azurerm_resource_group.app.location

  tags = local.common_tags
}

