locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  restore_task_name = "${var.database_name}-restore-to-${var.environment}"
  task_family  = "${var.application}-${var.environment}-${local.restore_task_name}"
  
  dump_task_name =  "${var.database_name}-dump-from-${var.task.from}"
  dump_task_family = "${var.application}-${var.task.from}-${local.dump_task_name}"
  dump_kms_key_alias = "alias/${local.task_family}"
  dump_bucket_name = local.task_family

  s3_permissions = [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:GetObjectTagging",
    "s3:GetObjectVersion",
    "s3:GetObjectVersionTagging"
  ]
}