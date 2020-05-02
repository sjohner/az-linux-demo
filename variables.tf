provider "azurerm" {
  # Whilst version is optional, it is strongly recommend using it to pin the version of the Provider being used
  version = "=2.7.0"

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  features {}
}

variable "subscription_id" {
  description = "Id of the subscription in which resources are deployed"
}

variable "client_id" {
  description = "Service Principal Id to authenticate to Azure"
}

variable "client_secret" {
  description = "Secret of the service principal used to authenticate to Azure"
}

variable "tenant_id" {
  description = "Id of the AAD tenant you are authenticating against"
}

variable "location" {
  default     = "westeurope"
  description = "The Azure region where resources are deployed"
}

variable "app_id" {
  default     = "blog"
  description = "The name of the app"
}

variable "stage" {
  default     = "dev"
  description = "The stage where the app is deployed"
}

variable "vm_size" {
  default     = "Standard_D1_v2"
  description = "The virtual machine size"
}

variable "admin_username" {
  description = "The admin username to connect to the new virtual machine"
}

variable "admin_ssh_key" {
  description = "The ssh public key to connect to the new virtual machine"
}