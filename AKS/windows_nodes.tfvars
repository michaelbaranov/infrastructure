node_pools = {
  windows = {
    name = "win"
    os_type = "Windows"
    node_count = 1
    size = "Standard_D4_v4"
    priority = "Spot"
  }
}