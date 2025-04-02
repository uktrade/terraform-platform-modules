resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.cluster_name}-ecs-execution-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = local.tags
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

resource "aws_iam_policy" "secrets_policy" {
  name        = "${local.cluster_name}-web-secrets-policy-tf"
  description = "Allow application to access secrets manager"
  policy      = data.aws_iam_policy_document.secrets_policy.json
}

data "aws_iam_policy_document" "secrets_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
        "arn:aws:secretsmanager:${local.region_account}:secret:*"
    ]
    condition  {
      test     = "StringEquals"
      variable = "ssm:ResourceTag/copilot-environment"
      values =  [var.environment]
    }
    condition  {
      test     = "StringEquals"
      variable = "aws:ResourceTag/copilot-application"
      values =  [var.application]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [
       "arn:aws:kms:${local.region_account}:key/*"
      ]
    condition  {
      test     = "StringEquals"
      variable = "ssm:ResourceTag/copilot-environment"
      values =  [var.environment]
    }
    condition  {
      test     = "StringEquals"
      variable = "aws:ResourceTag/copilot-application"
      values =  [var.application]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:${local.region_account}:parameter/*"
    ]
    condition  {
      test     = "StringEquals"
      variable = "ssm:ResourceTag/copilot-environment"
      values =  [var.environment]
    }
    condition  {
      test     = "StringEquals"
      variable = "aws:ResourceTag/copilot-application"
      values =  [var.application]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:${local.region_account}:parameter/*"
    ]
    condition  {
      test     = "StringEquals"
      variable = "aws:ResourceTag/copilot-application"
      values =  ["__all__"]
    }
  }
}
