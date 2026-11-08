output "id" {
  description = "ID of the virtual machine."
  value       = azurerm_linux_virtual_machine.this.id
}

output "name" {
  description = "Name of the virtual machine."
  value       = azurerm_linux_virtual_machine.this.name
}

output "private_ip_address" {
  description = "Primary private IP address assigned to the virtual machine."
  value       = azurerm_linux_virtual_machine.this.private_ip_address
}

output "public_ip_address" {
  description = "Primary public IP address assigned to the virtual machine, if any."
  value       = azurerm_linux_virtual_machine.this.public_ip_address
}

output "network_interface_id" {
  description = "ID of the network interface created by the module, or null when existing network_interface_ids were passed in."
  value       = local.create_network_interface ? azurerm_network_interface.this[0].id : null
}

output "network_interface_ids" {
  description = "IDs of the network interfaces attached to the virtual machine, whether created by the module or passed in."
  value       = azurerm_linux_virtual_machine.this.network_interface_ids
}
