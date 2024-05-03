locals {
  tags = {
    application         = var.application
    copilot-application = var.application
    managed-by          = "DBT Platform - Terraform"
  }

  # Todo: This appears unused to tflint. Can it be safely deleted?
  # tflint-ignore: terraform_unused_declarations
  stage_config = yamldecode(file("${path.module}/stage_config.yml"))

  stages = [for env in var.environments : { type : "plan", env : env.name, approval : env.requires_approval, accounts : env.accounts }]
}
