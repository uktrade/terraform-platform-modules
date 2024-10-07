locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  dump_task_name = "${var.database_name}-dump-from-${var.environment}"
  task_family  = "${var.application}-${var.environment}-${local.dump_task_name}"
  dump_kms_key_alias = "alias/${local.task_family}"
  dump_bucket_name = local.task_family

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