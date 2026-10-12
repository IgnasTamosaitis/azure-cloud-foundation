resource "azurerm_resource_group" "main" {
  name     = "rg-cloud-foundation-dev"
  location = "North Europe"
  tags = {
    environment = "dev"
    project     = "cloud-foundation"
  }
}
