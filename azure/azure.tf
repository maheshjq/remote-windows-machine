provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "myVm_group" {
  name     = "myVm_group"
  location = "Central India"
}

resource "azurerm_virtual_network" "myVm_vnet" {
  name                = "myVm-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myVm_group.location
  resource_group_name = azurerm_resource_group.myVm_group.name
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.myVm_group.name
  virtual_network_name = azurerm_virtual_network.myVm_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "myVm_ip" {
  name                = "myVm-ip"
  location            = azurerm_resource_group.myVm_group.location
  resource_group_name = azurerm_resource_group.myVm_group.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "myVm_nic" {
  name                = "myVm-nic"
  location            = azurerm_resource_group.myVm_group.location
  resource_group_name = azurerm_resource_group.myVm_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myVm_ip.id
  }
}

resource "azurerm_windows_virtual_machine" "myVm" {
  name                  = "myVm"
  location              = azurerm_resource_group.myVm_group.location
  resource_group_name   = azurerm_resource_group.myVm_group.name
  size                  = "Standard_B1s"
  admin_username        = "trados2"
  admin_password        = "Gemwriting1!" # Change this to a secure password
  network_interface_ids = [azurerm_network_interface.myVm_nic.id]
  zone                  = "1"
  license_type          = "Windows_Client"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-22h2-pro-g2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.myVm_sa.primary_blob_endpoint
  }

  secure_boot_enabled      = true
  vtpm_enabled             = true
  enable_automatic_updates = false

  additional_capabilities {
    ultra_ssd_enabled = false
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_account" "myVm_sa" {
  name                     = "myvmsa${random_integer.sa_suffix.result}"
  resource_group_name      = azurerm_resource_group.myVm_group.name
  location                 = azurerm_resource_group.myVm_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_integer" "sa_suffix" {
  min = 10000
  max = 99999
}

output "azure_public_ip" {
  description = "The public IP address of the Azure Windows Server instance"
  value       = azurerm_public_ip.myVm_ip.ip_address
}
