provider "azurerm" {
    version = "=2.7.0"
    subscription_id = var.subscription_id
    features {}
}

variable "subscription_id" {
    description = "Subscription ID for provisioning resources in Azure"
}

variable "location" {
    description = "The default Azure region for the resource provisioning"
}

variable "vm_size" {
    description = "The default virtual machine SKU"
}

variable "admin_username" {
    description = "The default admin username to connect to the new virtual machine"
}

variable "tags" {
    description = "The default tags applied to the resources"
}