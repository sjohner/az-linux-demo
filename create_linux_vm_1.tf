resource "azurerm_resource_group" "resourcegroup" {
    name     = "linuxdemo-prod-rg-${random_id.randomId.hex}"
    location = "westeurope"

    tags {
        environment = "Terraform Demo"
    }
}

resource "azurerm_virtual_network" "virtualnetwork" {
    name                = "${azurerm_virtual_machine.virtualmachine.name}VNET"
    address_space       = ["10.0.0.0/16"]
    location            = "westeurope"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

    tags {
        environment = "Terraform Demo"
    }
}

resource "azurerm_subnet" "subnet" {
    name                 = "${azurerm_virtual_machine.virtualmachine.name}Subnet"
    resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
    virtual_network_name = "${azurerm_virtual_network.virtualnetwork.name}"
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "publicip" {
    name                         = "${azurerm_virtual_machine.virtualmachine.name}PublicIP"
    location                     = "westeurope"
    resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_security_group" "networksecuritygroup" {
    name                = "${azurerm_virtual_machine.virtualmachine.name}NSG"
    location            = "westeurope"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_interface" "nic" {
    name                = "azl${random_id.randomId.hex}VMNic"
    location            = "westeurope"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
    network_security_group_id = "${azurerm_network_security_group.networksecuritygroup.id}"

    ip_configuration {
        name                          = "azl${random_id.randomId.hex}VMNicConfig"
        subnet_id                     = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

resource "random_id" "randomId" {
#    keepers = {
#        # Generate a new ID only when a new resource group is defined
#        resource_group = "${azurerm_resource_group.resourcegroup.name}"
#    }

    byte_length = 8
}

resource "azurerm_storage_account" "storageaccount" {
    name                = "demodata${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
    location            = "westeurope"
    account_replication_type = "LRS"
    account_tier = "Standard"

    tags {
        environment = "Terraform Demo"
    }
}

resource "azurerm_virtual_machine" "virtualmachine" {
    name                  = "azl${random_id.randomId.hex}"
    location              = "westeurope"
    resource_group_name   = "${azurerm_resource_group.resourcegroup.name}"
    network_interface_ids = ["${azurerm_network_interface.nic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "azl${random_id.randomId.hex}_OsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "azl${random_id.randomId.hex}"
        admin_username = "stefan"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/stefan/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqdUGETn/i/Vy7K+Xz6O4UYIC9MfW3FjnUfXcGOrEOi34M9T/iAkXbRmRWrzuM4Xqeo2976luzUsvBsBUQFpMdbO1yiFC5MFQu0ixzYigMjvfaMTosb1JV/M/HidbuGQQI20CEps3TTxlobWe0O5a7hwg27/jBSpVoJzuQGEMTrXNuP9d3rHCfxW5VDCNR9d0oQXiYp4D/izUIBrCws6O1Q5GhCulsZYOaqEcnRQf9z0D2mTIcONGqvzt4zBCmVbwN8vK8IIVa8M15HZrhYT0qYeR1isQnbXHOh1zXHm2qhLeMTRDp3NOgJybDkIB7RFRU3dDfXBk9NAa5W8ZEDXWh"
        }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.storageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Terraform Demo"
    }
}
