terraform {
  required_version = ">= 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.38.0"
    }
  }
}

resource "aws_ssm_parameter" "master-secret-arn" {
  name  = "/copilot/${var.application}/${var.environment}/secrets/${local.rds_master_secret_name}"
  type  = "SecureString"
  value = aws_db_instance.default.master_user_secret[0].secret_arn
  tags  = local.tags
}

