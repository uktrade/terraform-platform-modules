locals {
  tags = {
    application         = var.application
    environment         = var.environment
    managed-by          = "DBT Platform - Terraform"
    copilot-application = var.application
    copilot-environment = var.environment
  }

  kms_alias_name = strcontains(var.config.bucket_name, "pipeline") ? "${var.config.bucket_name}-key" : "${var.application}-${var.environment}-${var.config.bucket_name}-key"

  base_statements = [
    {
      Sid = "Enable IAM User Permissions"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "kms:*"
      Resource = "*"
    }
  ]

  cloudfront_statement = {
    Sid = "Allow CloudFront to Use Key"
    Effect = "Allow"
    Principal = {
      AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.oai[0].id}"
    }
    Action = "kms:Decrypt"
    Resource = "*"
  }

  statements = var.config.serve_static ? local.base_statements + [local.cloudfront_statement] : local.base_statements
}
