data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda-execution-policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ssm:DeleteParameter",
      "ssm:PutParameter",
      "ssm:AddTagsToResource",
      "kms:Decrypt",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetRandomPassword",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
    "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role" "lambda-execution-role" {
  name               = "${local.name}-lambda-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json

  inline_policy {
    name   = "${local.name}-execution-policy"
    policy = data.aws_iam_policy_document.lambda-execution-policy.json
  }
}

data "aws_security_group" "rds-endpoint" {
  name = "${var.vpc_name}-rds-endpoint-sg"
}

resource "aws_lambda_function" "lambda" {
  filename      = "${path.module}/manage_users.zip"
  function_name = "${local.name}-rds-create-user"
  role          = aws_iam_role.lambda-execution-role.arn
  handler       = "manage_users.handler"
  runtime       = "python3.11"
  memory_size   = 128
  timeout       = 10

  layers = ["arn:aws:lambda:eu-west-2:763451185160:layer:python-postgres:1"]

  vpc_config {
    security_group_ids = [aws_security_group.default.id, data.aws_security_group.rds-endpoint.id]
    subnet_ids         = data.aws_subnets.private-subnets.ids
  }
}

resource "aws_lambda_invocation" "create-application-user" {
  function_name = aws_lambda_function.lambda.function_name

  input = jsonencode({
    CopilotApplication  = var.application
    CopilotEnvironment  = var.environment
    MasterUserSecretArn = aws_db_instance.default.master_user_secret[0].secret_arn
    SecretDescription   = "RDS application user secret for ${local.name}"
    SecretName          = "/copilot/${var.application}/${var.environment}/secrets/${local.application_user_secret_name}"
    Username            = "application_user"
    Permissions = [
      "SELECT",
      "INSERT",
      "UPDATE",
      "DELETE",
      "TRIGGER"
    ],
    DbHost               = aws_db_instance.default.address,
    DbPort               = aws_db_instance.default.port,
    DbEngine             = aws_db_instance.default.engine,
    DbName               = aws_db_instance.default.db_name,
    dbInstanceIdentifier = aws_db_instance.default.resource_id,
  })

  depends_on = [
    aws_lambda_function.lambda,
    aws_db_instance.default,
  ]
}

resource "aws_lambda_invocation" "create-readonly-user" {
  function_name = aws_lambda_function.lambda.function_name

  input = jsonencode({
    CopilotApplication  = var.application
    CopilotEnvironment  = var.environment
    MasterUserSecretArn = aws_db_instance.default.master_user_secret[0].secret_arn
    SecretDescription   = "RDS application user secret for ${local.name}"
    SecretName          = "/copilot/${var.application}/${var.environment}/secrets/${local.read_only_secret_name}"
    Username            = "readonly_user"
    Permissions = [
      "SELECT",
    ],
    DbHost               = aws_db_instance.default.address,
    DbPort               = aws_db_instance.default.port,
    DbEngine             = aws_db_instance.default.engine,
    DbName               = aws_db_instance.default.db_name,
    dbInstanceIdentifier = aws_db_instance.default.resource_id,
  })

  depends_on = [
    aws_lambda_function.lambda,
    aws_db_instance.default,
  ]
}
