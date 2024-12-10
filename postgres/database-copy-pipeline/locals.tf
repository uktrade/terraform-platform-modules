locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  pipeline_name  = substr("${var.database_name}-${var.task.from}-to-${var.task.to}-copy-pipeline", 0, 48)
  region_account = "${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"
  from_account   = coalesce(var.task.from_account, data.aws_caller_identity.current.account_id)
  dump_role_arn  = "arn:aws:iam::${local.from_account}:role/${var.application}-${var.task.from}-${var.database_name}-dump-task"
}
