provider "azurerm" {
    subscription_id = "${var.subscription_id}"
 }

variable "subscription_id" {
    description = "Subscription ID for provisioning resources in Azure"
}

variable "location" {
    description = "The default Azure region for the resource provisioning"
}