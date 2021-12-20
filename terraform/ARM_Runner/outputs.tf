# Outputs block
output "storageAccountName" {
  value = azurerm_template_deployment.arm_deployment.outputs["storageAccountName"]
}