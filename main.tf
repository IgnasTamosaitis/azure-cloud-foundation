resource "azurerm_resource_group" "main" {
  name     = "rg-cloud-foundation-${var.environment}"
  location = var.location
  tags = {
    environment = var.environment
    project     = "cloud-foundation"
  }
}
