resource "random_string" "random" {
  length = 4
  special = false
  lower = true
  upper = false
}

resource "azurerm_resource_group" "rg" {
  location = var.location
  name = var.resource_group_name
  tags = var.tags
}

resource "azurerm_container_registry" "acr" {
  location = var.location
  name = var.container_registry_name
  resource_group_name = azurerm_resource_group.rg.name
  sku = "Premium"
}

resource "azurerm_virtual_network" "vnet" {
  address_space = var.address_space
  location = var.location
  name = "${var.resource_group_name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  address_prefixes = var.subnet
  name = "${var.resource_group_name}-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "pip" {
  location = var.location
  name = "${var.resource_group_name}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
  sku = var.publicip_sku
  lifecycle {
    ignore_changes = [
      domain_name_label,
      tags
    ]
  }
}

resource "azurerm_kubernetes_cluster" "cluster" {
  dns_prefix = "${var.dns_prefix}-${random_string.random.result}"
  location = var.location
  kubernetes_version = var.kubernetes_version
  name = "${var.resource_group_name}-cluster"
  resource_group_name = azurerm_resource_group.rg.name
  default_node_pool {
    name = "defaultpool"
    vm_size = var.machinesize
    node_count = 2
    availability_zones = ["1"]
    vnet_subnet_id = azurerm_subnet.subnet.id
  }

  network_profile {
    network_plugin = var.networkplugin
    load_balancer_sku = var.loadbalancer_sku
    network_policy = var.networkpolicy
  }

  identity {
    type = "SystemAssigned"
  }
  
  role_based_access_control {
    enabled = true
  }

  node_resource_group = "${azurerm_resource_group.rg.name}-resources"

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "assignment" {
  principal_id = azurerm_kubernetes_cluster.cluster.kubelet_identity.0.object_id
  role_definition_name = "AcrPull"
  scope = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

resource "azurerm_storage_account" "storage" {
  name = "trmmstorage"
  resource_group_name = azurerm_kubernetes_cluster.cluster.node_resource_group
  location = var.location
  account_tier = "Premium"
  account_replication_type = "LRS"
  account_kind = "FileStorage"
  large_file_share_enabled = true
  allow_blob_public_access = true
  tags = var.tags
}

resource "azurerm_storage_share" "share" {
  name = "sharedstorage"
  storage_account_name = azurerm_storage_account.storage.name
  quota = 100
}

resource "azurerm_managed_disk" "postgresdisk" {
  name = "postgres"
  location = var.location
  resource_group_name = "${azurerm_resource_group.rg.name}-resources"
  storage_account_type = "StandardSSD_ZRS"
  create_option = "Empty"
  disk_size_gb = 16
  tags = var.tags
}

resource "azurerm_managed_disk" "mongodbdisk" {
  name = "mongodb"
  location = var.location
  resource_group_name = "${azurerm_resource_group.rg.name}-resources"
  storage_account_type = "StandardSSD_ZRS"
  create_option = "Empty"
  disk_size_gb = 16
  tags = var.tags
}

resource "azurerm_managed_disk" "meshdisk" {
  name = "meshdata"
  location = var.location
  resource_group_name = "${azurerm_resource_group.rg.name}-resources"
  storage_account_type = "StandardSSD_ZRS"
  create_option = "Empty"
  disk_size_gb = 16
  tags = var.tags
}

resource "azurerm_managed_disk" "redis" {
  name = "redis"
  location = var.location
  resource_group_name = "${azurerm_resource_group.rg.name}-resources"
  storage_account_type = "StandardSSD_ZRS"
  create_option = "Empty"
  disk_size_gb = 16
  tags = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name = var.vaultname
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name = "standard"
  tenant_id = data.azurerm_client_config.current.tenant_id

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "Delete",
      "List",
      "Set",
    ]

    storage_permissions = [
      "Get",
    ]
  }

  lifecycle {
    ignore_changes = [
      access_policy
    ]
  }
}