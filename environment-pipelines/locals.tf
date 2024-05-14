locals {
  tags = {
    application         = var.application
    copilot-application = var.application
    managed-by          = "DBT Platform - Terraform"
  }

  stages = [for env in var.environments : { type : "plan", env : env.name, approval : env.requires_approval, accounts : env.accounts }]
}
