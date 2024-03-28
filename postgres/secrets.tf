resource "aws_ssm_parameter" "master-secret-arn" {
  name  = "/copilot/${var.application}/${var.environment}/secrets/${upper(replace("${var.name}-rds-master-arn", "-", "_"))}"
  type  = "SecureString"
  value = aws_db_instance.default.master_user_secret[0].secret_arn
  tags  = local.tags
}

