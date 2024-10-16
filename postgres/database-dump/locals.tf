locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  task_name          = "${var.application}-${var.environment}-${var.database_name}-dump"
  dump_kms_key_alias = "alias/${local.task_name}"
  dump_bucket_name   = local.task_name

  s3_permissions = [
    "s3:ListBucket",
    "s3:PutObject",
    "s3:PutObjectAcl",
    "s3:PutObjectTagging",
    "s3:GetObjectTagging",
    "s3:GetObjectVersion",
    "s3:GetObjectVersionTagging"
  ]
}