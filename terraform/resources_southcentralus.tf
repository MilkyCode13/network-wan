resource "azurerm_virtual_network" "vnet_southcentralus" {
  name                = "task-vnet-southcentralus"
  location            = "South Central US"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.3.0.0/16"]
}

resource "azurerm_subnet" "subnet_southcentralus_external" {
  name                 = "task-subnet-southcentralus-external"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_southcentralus.name
  address_prefixes     = ["10.3.0.0/24"]
}

resource "azurerm_subnet" "subnet_southcentralus_internal" {
  name                 = "task-subnet-southcentralus-internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_southcentralus.name
  address_prefixes     = ["10.3.1.0/24"]
}

resource "azurerm_public_ip" "ip_southcentralus" {
  name                = "task-ip-southcentralus"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "South Central US"
  allocation_method   = "Static"
  domain_name_label   = "milkycode-southcentralusus"
}

resource "azurerm_network_interface" "cisco_southcentralus_nic_external" {
  name                = "task-cisco-southcentralus-nic-external"
  location            = "South Central US"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "task-cisco-southcentralus-nic-external-ip"
    subnet_id                     = azurerm_subnet.subnet_southcentralus_external.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.3.0.4"
    public_ip_address_id          = azurerm_public_ip.ip_southcentralus.id
  }
}

resource "azurerm_network_interface" "cisco_southcentralus_nic_internal" {
  name                = "task-cisco-southcentralus-nic-internal"
  location            = "South Central US"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "task-cisco-southcentralus-nic-internal-ip"
    subnet_id                     = azurerm_subnet.subnet_southcentralus_internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.3.1.4"
  }
}

resource "azurerm_virtual_machine" "cisco_southcentralus" {
  name                         = "task-cisco-southcentralus"
  location                     = "South Central US"
  resource_group_name          = azurerm_resource_group.rg.name
  vm_size                      = "Standard_B2s"
  network_interface_ids        = [azurerm_network_interface.cisco_southcentralus_nic_external.id, azurerm_network_interface.cisco_southcentralus_nic_internal.id]
  primary_network_interface_id = azurerm_network_interface.cisco_southcentralus_nic_external.id

  plan {
    publisher = "cisco"
    product   = "cisco-csr-1000v"
    name      = "17_3_3-payg-ax"
  }

  storage_image_reference {
    publisher = "cisco"
    offer     = "cisco-csr-1000v"
    sku       = "17_3_3-payg-ax"
    version   = "latest"
  }

  storage_os_disk {
    name              = "task-cisco-southcentralus-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      key_data = file("../.ssh/id_rsa.pub")
      path     = "/home/azadmin/.ssh/authorized_keys"
    }
  }

  os_profile {
    admin_username = "azadmin"
    # admin_password = "Q4MTdlMzc0Y2UyMmR"
    computer_name = "task-cisco-southcentralus"
  }
}
