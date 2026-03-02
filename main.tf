provider "azurerm" {
  features {}
}

# 1. Create the Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. Create Network Security Group (NSG) to allow Ping (ICMP)
resource "azurerm_network_security_group" "nsg" {
  name                = "project-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-icmp-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/8" # Covers both VNet A and VNet B
    destination_address_prefix = "10.0.0.0/8"
  }
}

# 3. Create VNet A
resource "azurerm_virtual_network" "vnet_a" {
  name                = var.vnet_a_name
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet_a" {
  name                 = "subnet-a"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_a.name
  address_prefixes     = ["10.1.1.0/24"]
}

# 4. Create VNet B
resource "azurerm_virtual_network" "vnet_b" {
  name                = var.vnet_b_name
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet_b" {
  name                 = "subnet-b"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_b.name
  address_prefixes     = ["10.2.1.0/24"]
}

# 5. VNet Peering
resource "azurerm_virtual_network_peering" "peering_a_to_b" {
  name                         = "peering-A-to-B"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet_a.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_b.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "peering_b_to_a" {
  name                         = "peering-B-to-A"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet_b.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_a.id
  allow_virtual_network_access = true
}

# ---------------------------------------------------------
# COMPUTE SECTION - VNET A
# ---------------------------------------------------------

resource "azurerm_network_interface" "nic_a" {
  count               = 2
  name                = "nic-vnet-a-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_a.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG with NICs in VNet A
resource "azurerm_network_interface_security_group_association" "assoc_a" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.nic_a[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm_a" {
  count               = 2
  name                = "vm-a-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.nic_a[count.index].id,
  ]

  os_disk {
    name                 = "${var.vnet_a_name}-disk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# ---------------------------------------------------------
# COMPUTE SECTION - VNET B
# ---------------------------------------------------------

resource "azurerm_network_interface" "nic_b" {
  count               = 2
  name                = "nic-vnet-b-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_b.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG with NICs in VNet B
resource "azurerm_network_interface_security_group_association" "assoc_b" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.nic_b[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm_b" {
  count               = 2
  name                = "vm-b-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.nic_b[count.index].id,
  ]

  os_disk {
    name                 = "vnet-b-disk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}