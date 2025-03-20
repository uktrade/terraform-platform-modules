locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  base_env_config = {
    for name, config in var.env_config : name => {
      account : lookup(lookup(lookup(merge(lookup(var.env_config, "*", {}), config), "accounts", {}), "deploy", {}), "id", {})
    } if name != "*"
  }

  pipeline_name  = "${var.database_name}-${var.task.from}-to-${var.task.to}-copy-pipeline"
  region_account = "${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"
  from_account   = lookup(local.base_env_config, var.task.from, {})
  to_account     = lookup(local.base_env_config, var.task.to, {})
  dump_role_arn  = "arn:aws:iam::${local.from_account}:role/${var.application}-${var.task.from}-${var.database_name}-dump-task"
  load_role_arn  = "arn:aws:iam::${local.to_account}:role/${var.application}-${var.task.to}-${var.database_name}-load-task"
}
