variable "kubernetes_version" {
  default = "1.19.7"
}

variable "location" {
  default = "northeurope"
}

variable "rg_name" {
  default = "mb-aks"
}

variable "log_analytics_workspace"{
  type = object({
    name = string
    sku = string
  })
  default = ({
    name = "mb-la-ws"
    sku = "PerGB2018"
  })
}

variable "cluster_name" {
  default = "mb-aks"
}

variable "dns_prefix" {
  default = "mb-test-aks"
}

variable "default_node_pool" {
  type = object({
    agent_count = number
    size = string
  })
  default = {
    agent_count = 1 
    size = "Standard_D2_v2"
  }
}

variable "node_pools" {
  type = map(any)
  default = {}
}