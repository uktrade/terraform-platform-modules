locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  task_name = "${var.application}-${var.environment}-${var.database_name}-load"

  dump_task_name     = "${var.application}-${var.task.from}-${var.database_name}-dump"
  dump_kms_key_alias = "alias/${local.dump_task_name}"
  dump_bucket_name   = local.dump_task_name

  ecr_repository_arn = "arn:aws:ecr-public::763451185160:repository/database-copy"

  s3_permissions = [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:GetObjectTagging",
    "s3:GetObjectVersion",
    "s3:GetObjectVersionTagging"
  ]
}