locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  pipeline_name = substr("${var.database_name}-${var.task.from}-to-${var.task.to}-copy-pipeline", 0, 48)
  to_account    = coalesce(var.task.to_account, data.aws_caller_identity.current.account_id)
  from_account  = coalesce(var.task.from_account, data.aws_caller_identity.current.account_id)
}
