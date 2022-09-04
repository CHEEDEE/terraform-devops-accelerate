resource "azurerm_lb" "basic" {
  name                = "TestLoadBalancer"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.example.name
}