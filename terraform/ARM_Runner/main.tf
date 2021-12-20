# Required provideres block
terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~> 2.0"
        }
    }
}

# Providers block
provider "azurerm" {
    features {}

#   subscription_id = var.azure_creds.subscription_id
}

# Data Block
data "http" "ARM_Template" {
  url = "https://raw.githubusercontent.com/QualiSystemsLab/Torque-Project-Amplius/master/arm_templates/${var.template_name}/template.json"
}

# Resources block
resource "azurerm_template_deployment" "arm_deployment" {
  name                = "${var.torque_sandbox_id}-deployment"
  resource_group_name = "LeeorV_Colony"

  template_body = data.http.ARM_Template.body

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "storageAccountType" = "Standard_GRS"
  }

  deployment_mode = "Incremental"
}