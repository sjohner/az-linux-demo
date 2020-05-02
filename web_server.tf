locals {
  web_vm_name = "${var.app_id}-${var.stage}-web-vm"
}

data "azurerm_platform_image" "ubuntu_server" {
  location  = var.location
  publisher = "Canonical"
  offer     = "UbuntuServer"
  sku       = var.vm_image_sku
}

# Read bash cloud init file
data "template_file" "web-vm-cloud-init" {
  template = file("web_cloud_init.sh")
}

resource "azurerm_storage_account" "diag-sa" {
  name                     = lower("${var.app_id}${var.stage}sa")
  resource_group_name      = azurerm_resource_group.resourcegroup.name
  location                 = var.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  tags                     = var.tags
}

resource "azurerm_public_ip" "web-pip" {
  name                = "${var.app_id}-${var.stage}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.pip_domain_name_label}-${var.stage}"
  tags                = var.tags
}

resource "azurerm_network_interface" "web-vm-nic" {
  name                = "${var.app_id}-${var.stage}-web-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  tags                = var.tags
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web-subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.web-pip.id
  }
}

resource "azurerm_linux_virtual_machine" "web-vm" {
  name                            = local.web_vm_name
  resource_group_name             = azurerm_resource_group.resourcegroup.name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  computer_name                   = local.web_vm_name
  # Not using source_image_id since getting error "Can not parse "source_image_id" as a resource id". Opend issue #6745
  #source_image_id = data.azurerm_platform_image.ubuntu_server.id
  tags = var.tags

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # Execute cloud init script to install web vm resources
  custom_data = base64encode(data.template_file.web-vm-cloud-init.rendered)

  network_interface_ids = [
    azurerm_network_interface.web-vm-nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_key
  }

  os_disk {
    name                 = "${local.web_vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diag-sa.primary_blob_endpoint
  }
}


# Get public ip address from newly created virtual machine
data "azurerm_public_ip" "web-pip" {
  name                = azurerm_public_ip.web-pip.name
  resource_group_name = azurerm_linux_virtual_machine.web-vm.resource_group_name
}

output "public_ip_address" {
  value = data.azurerm_public_ip.web-pip.ip_address
}

output "public_ip_fqdn" {
  value = azurerm_public_ip.web-pip.fqdn
}

output "vm_image_version" {
  value = data.azurerm_platform_image.ubuntu_server.version
}