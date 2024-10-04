locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  is_data_dump = var.task.from == var.environment
  
  dump_task_name = "${var.database_name}-dump-from-${var.task.from}"
  restore_task_name = "${var.database_name}-restore-to-${var.task.to}"
  
  task_type    = "${local.is_data_dump ? "dump-from" : "restore-to"}-${local.is_data_dump ? var.task.from : var.task.to}"
  task_name    = "${var.database_name}-${local.task_type}"
  task_family  = "${var.application}-${var.environment}-${local.dump_task_name}"


  s3_permissions = local.is_data_dump ? [
    "s3:ListBucket",
    "s3:PutObject",
    "s3:PutObjectAcl",
    "s3:PutObjectTagging",
    "s3:GetObjectTagging",
    "s3:GetObjectVersion",
    "s3:GetObjectVersionTagging"
    ] : [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:GetObjectTagging",
    "s3:GetObjectVersion",
    "s3:GetObjectVersionTagging"
  ]
}