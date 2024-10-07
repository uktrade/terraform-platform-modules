locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  task_name = "${var.environment}-${var.database_name}-restore"

  dump_task_name     = "${var.task.from}-${var.database_name}-dump"
  dump_kms_key_alias = "alias/${local.dump_task_name}"
  dump_bucket_name   = local.dump_task_name

  s3_permissions = [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:GetObjectTagging",
    "s3:GetObjectVersion",
    "s3:GetObjectVersionTagging"
  ]
}