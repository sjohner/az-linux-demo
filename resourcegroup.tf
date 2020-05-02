resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.app_id}-${var.stage}-rg"
  location = var.location
  tags     = var.tags
}