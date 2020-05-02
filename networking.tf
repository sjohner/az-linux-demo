resource "azurerm_virtual_network" "virtualnetwork" {
    name = "${var.app_id}-${var.stage}-vnet"
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

# Create network security group and allow ports 80 (HTTP) and 22 (SSH)
resource "azurerm_network_security_group" "web-nsg" {
    name = "${var.app_id}-${var.stage}-web-nsg"
    location = var.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    tags = var.tags
    
    # Create allow SSH rule only in dev/test stages
    dynamic "security_rule" {
        for_each = var.stage == "prod" ? [] : [var.stage]
            content {
                name = "allow-ssh"
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
    }

    security_rule {
        name = "allow-http"
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

resource "azurerm_subnet_network_security_group_association" "web-nsg-association" {
  subnet_id = azurerm_subnet.web-subnet.id
  network_security_group_id = azurerm_network_security_group.web-nsg.id
}

/* resource "azurerm_subnet_network_security_group_association" "db-nsg-association" {
  subnet_id = azurerm_subnet.db-subnet.id
  network_security_group_id = azurerm_network_security_group.db-nsg.id
} */



