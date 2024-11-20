# Fetch the secret value from Secrets Manager
data "aws_secretsmanager_secret_version" "origin_verify_secret_version" {
  secret_id  = aws_secretsmanager_secret.origin-verify-secret.id
  version_id = aws_secretsmanager_secret_version.secret-value.version_id
}

resource "aws_secretsmanager_secret" "origin-verify-secret" {
  name        = "${var.application}-${var.environment}-origin-verify-header-secret"
  description = "Secret used for Origin verification in WAF rules"
  kms_key_id  = aws_kms_key.origin_verify_secret_key.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_policy" "secret_policy" {
  secret_arn = aws_secretsmanager_secret.origin-verify-secret.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAssumedRoleToAccessSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.origin-verify-secret.arn
        Principal = {
          AWS = "arn:aws:iam::${var.dns_account_id}:role/environment-pipeline-assumed-role"
        }
      }
    ]
  })
}

resource "aws_secretsmanager_secret_version" "secret-value" {
  secret_id     = aws_secretsmanager_secret.origin-verify-secret.id
  secret_string = jsonencode({ "HEADERVALUE" = random_password.origin-secret.result })

  lifecycle {
    # Use `ignore_changes` to allow rotation without Terraform overwriting the value
    ignore_changes = [secret_string]
  }
}

resource "aws_kms_key" "origin_verify_secret_key" {
  description             = "KMS key for ${var.application}-${var.environment}-origin-verify-header-secret"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

resource "aws_kms_alias" "origin_verify_secret_key_alias" {
  name          = "alias/${var.application}-${var.environment}-origin-verify-header-secret-key"
  target_key_id = aws_kms_key.origin_verify_secret_key.key_id
}
