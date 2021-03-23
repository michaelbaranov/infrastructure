terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }

  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
    byte_length = 8
}

resource "random_password" "windows_admin_password" {
  length      = 16
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

resource "random_password" "windows_admin_username" {
  length    = 16
  min_upper = 1
  min_lower = 1
  special   = false
}

resource "azurerm_log_analytics_workspace" "la" {
    name                = "${var.log_analytics_workspace.name}-${random_id.log_analytics_workspace_name_suffix.dec}"
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
    sku                 = var.log_analytics_workspace.sku
}

resource "azurerm_log_analytics_solution" "la" {
    solution_name         = "ContainerInsights"
    location              = azurerm_log_analytics_workspace.la.location
    resource_group_name   = azurerm_resource_group.rg.name
    workspace_resource_id = azurerm_log_analytics_workspace.la.id
    workspace_name        = azurerm_log_analytics_workspace.la.name

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

resource "azurerm_kubernetes_cluster" "k8s" {
    name                = var.cluster_name
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    dns_prefix          = var.dns_prefix

    default_node_pool {
        name            = "default"
        node_count      = var.default_node_pool.agent_count
        vm_size         = var.default_node_pool.size
        availability_zones = ["1"]
    }

    identity {
      type = "SystemAssigned"
    }

    windows_profile {
      admin_username = random_password.windows_admin_username.result
      admin_password = random_password.windows_admin_password.result
    }

    addon_profile {
        oms_agent {
        enabled                    = true
        log_analytics_workspace_id = azurerm_log_analytics_workspace.la.id
        }
    }

    network_profile {
      network_plugin = "azure"
    }

    tags = {
        Environment = "Development"
    }
}

resource "azurerm_kubernetes_cluster_node_pool" "node_pools" {
    for_each = var.node_pools
    kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id
    name                  = each.value.name
    vm_size               = each.value.size
    node_count            = each.value.node_count
    os_type               = each.value.os_type
    priority              = each.value.priority
    availability_zones    = ["1"]
    tags = {
      Environment = "Development"
    }
}
