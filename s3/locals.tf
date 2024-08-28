locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  kms_alias_name = strcontains(var.config.bucket_name, "pipeline") ? "${var.config.bucket_name}-key" : "${var.application}-${var.environment}-${var.config.bucket_name}-key"
  
  readonly_permissions_set = [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:GetObjectTagging",
    "s3:GetObjectVersion",
    "s3:GetObjectVersionTagging"
  ]

  writeonly_permission_set = [
    "s3:PutObject",
    "s3:PutObjectAcl",
    "s3:PutObjectTagging"
  ]

  permissions_map = {
    "READONLY" : local.readonly_permissions_set,
    "READWRITE" : local.readonly_permissions_set + local.writeonly_permission_set,
    "WRITEONLY" : local.writeonly_permission_set,
  }

  cross_account_access_permissions = try(lookup(permissions_map, var.config.cross_account_access.access_type, []), [])
  
  # bucket_actions = try({ for action in var.config.cross_account_access.bucket_actions : action => "s3:${action}" }, "")
}
