locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  kms_alias_name = strcontains(var.config.bucket_name, "pipeline") ? "${var.config.bucket_name}-key" : "${var.application}-${var.environment}-${var.config.bucket_name}-key"
}
