# PostgreSQL Flexible Server is intentionally read through data.tf for now.
# Managing azurerm_postgresql_flexible_server directly requires the admin password
# when password auth is enabled, which would risk storing that secret in Terraform state.

resource "azurerm_postgresql_flexible_server_database" "ecommerce" {
  name      = "ecommerce"
  server_id = data.azurerm_postgresql_flexible_server.app.id

  charset   = "UTF8"
  collation = "en_US.utf8"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "AllowAllAzureServicesAndResourcesWithinAzureIps_2026-7-5_11-18-55"
  server_id        = data.azurerm_postgresql_flexible_server.app.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
