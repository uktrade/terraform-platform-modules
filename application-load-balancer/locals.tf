locals {
  tags = {
    copilot-application = var.application
    copilot-environment = var.environment
    managed-by = "Terraform"
  }
}
