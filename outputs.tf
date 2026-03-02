# Private IP addresses for VMs in VNet A
output "ips_vnet_a" {
  description = "List of private IP addresses for VMs in VNet A"
  value       = azurerm_network_interface.nic_a[*].private_ip_address
}

# Private IP addresses for VMs in VNet B
output "ips_vnet_b" {
  description = "List of private IP addresses for VMs in VNet B"
  value       = azurerm_network_interface.nic_b[*].private_ip_address
}

# Specific output for the first VM in VNet B to be used by the test pipeline
output "target_vm_ip" {
  description = "The IP address of the target VM for connectivity testing"
  value       = azurerm_network_interface.nic_b[0].private_ip_address
}