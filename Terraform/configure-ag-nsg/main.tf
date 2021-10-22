# Required provideres block
terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~> 2.0"
        }
    }
}

# Variables block
variable "torque_sandbox_id" {}

variable "app_name" {}

variable "app_port" {}

variable "source_cidr" {}

# Debugging only
variable "azure_creds" {}

# Providers block
provider "azurerm" {
    features {}

    subscription_id = var.azure_creds.subscription_id
}


# Data Block
data "azurerm_subnet" "ag_subnet" {
  name                 = "ag_subnet"
  virtual_network_name = "${var.torque_sandbox_id}_vnet"
  resource_group_name  = "${var.torque_sandbox_id}"
}

data "azurerm_resource_group" "torque_sandbox_rg" {
  name = "${var.torque_sandbox_id}"
}


# Resources block
resource "azurerm_network_security_group" "ag_nsg" {
  name                = "Application_Gateway_Subnet_NSG"
  location            = data.azurerm_resource_group.torque_sandbox_rg.location
  resource_group_name = data.azurerm_resource_group.torque_sandbox_rg.name

 security_rule {
    name                       = "Allow_AG_Management_Traffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65000-65535"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_rule" "app_nsg_rule" {
  resource_group_name = data.azurerm_resource_group.torque_sandbox_rg.name
  network_security_group_name = azurerm_network_security_group.ag_nsg.name
  name                       = "Allow_${var.app_name}_Traffic"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = var.app_port
  source_address_prefix      = var.source_cidr
  destination_address_prefix = data.azurerm_subnet.ag_subnet.address_prefixes[0]
}

resource "azurerm_subnet_network_security_group_association" "ag_subnet_ag_nsg_association" {
  subnet_id                 = data.azurerm_subnet.ag_subnet.id
  network_security_group_id = azurerm_network_security_group.ag_nsg.id
}

# Outputs block
