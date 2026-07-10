resource "azurerm_kubernetes_cluster" "app" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  dns_prefix          = "ecommerce-api-dns"

  kubernetes_version        = "1.35.5"
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"
  sku_tier                  = "Free"
  support_plan              = "KubernetesOfficial"

  role_based_access_control_enabled = true
  local_account_disabled            = false
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true

  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 168

  default_node_pool {
    name                   = "agentpool"
    vm_size                = "Standard_D2as_v5"
    node_count             = 1
    auto_scaling_enabled   = false
    max_pods               = 30
    os_disk_size_gb        = 128
    os_disk_type           = "Managed"
    os_sku                 = "Ubuntu"
    type                   = "VirtualMachineScaleSets"
    kubelet_disk_type      = "OS"
    scale_down_mode        = "Delete"
    node_public_ip_enabled = false

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "azure"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
    dns_service_ip      = "10.0.0.10"
    service_cidr        = "10.0.0.0/16"
    pod_cidr            = "10.244.0.0/16"
    ip_versions         = ["IPv4"]
  }


  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 8
    day_of_week = "Sunday"
    start_time  = "00:00"
    start_date  = "2026-07-04T00:00:00Z"
    utc_offset  = "+00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 8
    day_of_week = "Sunday"
    start_time  = "00:00"
    start_date  = "2026-07-04T00:00:00Z"
    utc_offset  = "+00:00"
  }

  storage_profile {
    blob_driver_enabled         = false
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
