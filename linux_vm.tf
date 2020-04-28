resource "random_id" "randomId" {
    byte_length = 4
}

resource "azurerm_resource_group" "resourcegroup" {
    name = "tfdemo-prod-rg-${random_id.randomId.hex}"
    location = "${var.location}"
    tags = var.tags
}

resource "azurerm_virtual_network" "virtualnetwork" {
    name = "azl${random_id.randomId.hex}VNET"
    address_space = ["10.0.0.0/16"]
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
    tags = var.tags
}

resource "azurerm_subnet" "subnet1" {
    name = "azl${random_id.randomId.hex}Subnet-1"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
    virtual_network_name = "${azurerm_virtual_network.virtualnetwork.name}"
    address_prefix = "10.0.2.0/24"
}


resource "azurerm_subnet" "subnet2" {
    name = "azl${random_id.randomId.hex}Subnet-2"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
    virtual_network_name = "${azurerm_virtual_network.virtualnetwork.name}"
    address_prefix = "10.0.3.0/24"
}

resource "azurerm_public_ip" "publicip" {
    name = "azl${random_id.randomId.hex}PublicIP"
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
    allocation_method = "Dynamic"
    tags = var.tags
}

resource "azurerm_network_security_group" "networksecuritygroup" {
    name = "azl${random_id.randomId.hex}NSG"
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
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
    location = "${var.location}"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
    tags = var.tags
    ip_configuration {
        name = "azl${random_id.randomId.hex}VMNicConfig"
        subnet_id = "${azurerm_subnet.subnet1.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = "${azurerm_public_ip.publicip.id}"
    }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.networksecuritygroup.id
}

resource "azurerm_storage_account" "storageaccount" {
    name = "diag${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
    location = "${var.location}"
    account_replication_type = "LRS"
    account_tier = "Standard"
    tags = var.tags
}

resource "azurerm_linux_virtual_machine" "virtualmachine" {
    name = "azl${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
    location = "${var.location}"
    size = "Standard_DS1_v2"
    admin_username = "stefan"
    disable_password_authentication = true
    computer_name  = "azl${random_id.randomId.hex}"
    tags = var.tags
    network_interface_ids = [
        "${azurerm_network_interface.nic.id}"
    ]
    
    admin_ssh_key {
        username = "stefan"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        name = "azl${random_id.randomId.hex}_OsDisk"
        caching = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "18.04.0-LTS"
        version = "latest"
    }

    boot_diagnostics {
        storage_account_uri = "${azurerm_storage_account.storageaccount.primary_blob_endpoint}"
    }
}
