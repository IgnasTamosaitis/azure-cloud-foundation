output "vnet_id" {
  description = "Azure Virtual Network resource ID"
  value       = azurerm_virtual_network.main.id
}

output "resource_group_name" {
  description = "Azure Resource Group name"
  value       = azurerm_resource_group.main.name
}

output "app_subnet_id" {
  description = "Azure Application Subnet resource ID"
  value       = azurerm_subnet.app.id
}

output "data_subnet_id" {
  description = "Azure Data Subnet resource ID"
  value       = azurerm_subnet.data.id
}
