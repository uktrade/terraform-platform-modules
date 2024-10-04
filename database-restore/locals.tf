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

  s3_permissions = [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:GetObjectTagging",
    "s3:GetObjectVersion",
    "s3:GetObjectVersionTagging"
  ]
}