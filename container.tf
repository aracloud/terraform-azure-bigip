resource "random_string" "container_suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_container_group" "app" {
  name                = "app-${random_string.container_suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  os_type         = "Linux"
  ip_address_type = "Private"

  subnet_ids = [
    azurerm_subnet.subnet1.id  # ggf. anpassen!
  ]

  container {
    name   = "web"
    image  = "nginx:latest"
    cpu    = "1"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = {
    environment = "demo"
  }
}
