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
    name = "tfdemo-prod-rg-${random_id.randomId.hex}"
    location = var.location
    tags = var.tags
}

resource "azurerm_virtual_network" "virtualnetwork" {
    name = "azl${random_id.randomId.hex}VNET"
    address_space = ["10.0.0.0/16"]
    location = var.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    tags = var.tags
}

resource "azurerm_subnet" "subnet1" {
    name = "azl${random_id.randomId.hex}Subnet-1"
    resource_group_name = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.virtualnetwork.name
    address_prefix = "10.0.2.0/24"
}


resource "azurerm_subnet" "subnet2" {
    name = "azl${random_id.randomId.hex}Subnet-2"
    resource_group_name = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.virtualnetwork.name
    address_prefix = "10.0.3.0/24"
}

resource "azurerm_public_ip" "publicip" {
    name = "azl${random_id.randomId.hex}PublicIP"
    location = var.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    allocation_method = "Dynamic"
    domain_name_label = var.domain_name_label
    tags = var.tags
}

resource "azurerm_network_security_group" "networksecuritygroup" {
    name = "azl${random_id.randomId.hex}NSG"
    location = var.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    tags = var.tags
    security_rule {
        name = "SSH"
        priority = 1001
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "nic" {
    name = "azl${random_id.randomId.hex}VMNic"
    location = var.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    tags = var.tags
    ip_configuration {
        name = "azl${random_id.randomId.hex}VMNicConfig"
        subnet_id = azurerm_subnet.subnet1.id
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = azurerm_public_ip.publicip.id
    }
}

resource "azurerm_network_interface_security_group_association" "default_nsg_association" {
  network_interface_id = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.networksecuritygroup.id
}

resource "azurerm_storage_account" "storageaccount" {
    name = "diag${random_id.randomId.hex}"
    resource_group_name = azurerm_resource_group.resourcegroup.name
    location = var.location
    account_replication_type = "LRS"
    account_tier = "Standard"
    tags = var.tags
}

resource "azurerm_linux_virtual_machine" "virtualmachine" {
    name = "azl${random_id.randomId.hex}"
    resource_group_name = azurerm_resource_group.resourcegroup.name
    location = var.location
    size = var.vm_size
    admin_username = var.admin_username
    disable_password_authentication = true
    computer_name  = "azl${random_id.randomId.hex}"
    # Not using source_image_id since getting error "Can not parse "source_image_id" as a resource id". Opend issue #6745
    #source_image_id = data.azurerm_platform_image.ubuntu_server.id
    tags = var.tags

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    custom_data = base64encode(data.template_file.linux-vm-cloud-init.rendered)

    network_interface_ids = [
        azurerm_network_interface.nic.id
    ]
    
    admin_ssh_key {
        username = var.admin_username
        public_key = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        name = "azl${random_id.randomId.hex}_OsDisk"
        caching = "ReadWrite"
        storage_account_type = "StandardSSD_LRS"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storageaccount.primary_blob_endpoint
    }
}

# Get public ip address from newly created virtual machine
data "azurerm_public_ip" "example" {
    name = azurerm_public_ip.publicip.name
    resource_group_name = azurerm_linux_virtual_machine.virtualmachine.resource_group_name
}

# Read bash cloud init file
data "template_file" "linux-vm-cloud-init" {
  template = file("cloud_init.sh")
}

output "public_ip_address" {
  value = data.azurerm_public_ip.example.ip_address
}

output "public_ip_fqdn" {
  value = data.azurerm_public_ip.example.fqdn
}

output "vm_image_version" {
  value = data.azurerm_platform_image.ubuntu_server.version
}

