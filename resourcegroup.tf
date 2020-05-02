locals {
  tags = {
    environment = var.stage
    owner = "Stefan Johner"
    app = var.app_id
  }
}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.app_id}-${var.stage}-rg"
  location = var.location
  tags     = local.tags
}