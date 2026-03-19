resource "azurerm_kubernetes_cluster" "aks" {
  name                = "netflix-cluster"
  location            = "WestUS2"
  resource_group_name = "AZB48SLB"
  dns_prefix          = "netflixaks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }
}
