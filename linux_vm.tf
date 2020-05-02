locals {
    # Create Resource Group name
    rg_name = concat(var.app_id, var.stage, "-rg")
    vnet_name = concat(var.app_id, var.stage, "-vnet")
    pip_name = concat(var.app_id, var.stage, "-pip")
    webnsg_name = concat(var.app_id, var.stage, "-web-nsg")
    dbnsg_name = concat(var.app_id, var.stage, "-db-nsg")
    nic_name = concat(var.app_id, var.stage, "-web-vm-nic")
    diag_sa_name = concat(var.app_id, var.stage, "-sa")
    web_vm_name = concat(var.app_id, var.stage, "-web-vm")
}

data "azurerm_platform_image" "ubuntu_server" {
    location  = var.location
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = var.vm_image_sku
}

resource "random_id" "randomId" {
    byte_length = 4
}

resource "azurerm_resource_group" "resourcegroup" {
    name = locals.rg_name
    location = var.location
    tags = var.tags
}

resource "azurerm_virtual_network" "virtualnetwork" {
    name = locals.vnet_name
    address_space = ["10.0.0.0/16"]
    location = var.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    tags = var.tags
}

resource "azurerm_subnet" "web-subnet" {
    name = "${var.app_id}-web-subnet"
    resource_group_name = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.virtualnetwork.name
    address_prefix = "10.0.1.0/24"
}

resource "azurerm_subnet" "db-subnet" {
    name = "${var.app_id}-db-subnet"
    resource_group_name = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.virtualnetwork.name
    address_prefix = "10.0.2.0/24"
}

resource "azurerm_public_ip" "web-pip" {
    name = locals.pip_name
    location = var.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    allocation_method = "Dynamic"
    domain_name_label = var.pip_domain_name_label
    tags = var.tags
}

# Create network security group and allow ports 80 (HTTP) and 22 (SSH)
resource "azurerm_network_security_group" "web-nsg" {
    name = locals.webnsg_name
    location = var.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    tags = var.tags
    
    security_rule {
        name = "Allow SSH"
        description = "Allow inbound SSH from Internet to web servers"
        priority = 1001
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "Internet"
        destination_address_prefix = "*"
    }

    security_rule {
        name = "Allow HTTP"
        description = "Allow inbound HTTP from Internet to web servers"
        priority = 1002
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "Internet"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "web-vm-nic" {
    name = locals.nic_name
    location = var.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    tags = var.tags
    ip_configuration {
        name = "internal"
        subnet_id = azurerm_subnet.web-subnet.id
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = azurerm_public_ip.web-pip.id
    }
}

resource "azurerm_subnet_network_security_group_association" "web-nsg-association" {
  subnet_id = azurerm_subnet.web-subnet.id
  network_security_group_id = azurerm_network_security_group.web-nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db-nsg-association" {
  subnet_id = azurerm_subnet.db-subnet.id
  network_security_group_id = azurerm_network_security_group.db-nsg.id
}

resource "azurerm_storage_account" "diag-sa" {
    name = locals.diag_sa_name
    resource_group_name = azurerm_resource_group.resourcegroup.name
    location = var.location
    account_replication_type = "LRS"
    account_tier = "Standard"
    tags = var.tags
}

resource "azurerm_linux_virtual_machine" "web-vm" {
    name = locals.web_vm_name
    resource_group_name = azurerm_resource_group.resourcegroup.name
    location = var.location
    size = var.vm_size
    admin_username = var.admin_username
    disable_password_authentication = true
    computer_name  = locals.web_vm_name
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
        username = var.admin_username
        public_key = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        name = "${locals.web_vm_name}-OsDisk"
        caching = "ReadWrite"
        storage_account_type = "StandardSSD_LRS"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.diag-sa.primary_blob_endpoint
    }
}

# Get public ip address from newly created virtual machine
# data "azurerm_public_ip" "publicip" {
#     name = azurerm_public_ip.publicip.name
#     resource_group_name = azurerm_linux_virtual_machine.virtualmachine.resource_group_name
# }

# Read bash cloud init file
data "template_file" "web-vm-cloud-init" {
  template = file("web_cloud_init.sh")
}

output "public_ip_address" {
  value = azurerm_public_ip.web-pip.ip_address
}

output "public_ip_fqdn" {
  value = azurerm_public_ip.web-pip.fqdn
}

output "vm_image_version" {
  value = data.azurerm_platform_image.ubuntu_server.version
}

