data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CodePipeline
resource "aws_iam_role" "database_pipeline_codepipeline" {
  name               = "${local.pipeline_name}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.assume_codepipeline_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "assume_codepipeline_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "artifact_store_access_for_database_pipeline" {
  name   = "ArtifactStoreAccess"
  role   = aws_iam_role.database_pipeline_codepipeline.name
  policy = data.aws_iam_policy_document.access_artifact_store.json
}

data "aws_iam_policy_document" "access_artifact_store" {
  # checkov:skip=CKV_AWS_111:Permissions required to change ACLs on uploaded artifacts
  # checkov:skip=CKV_AWS_356:Permissions required to upload artifacts
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.artifact_store.arn,
      "${aws_s3_bucket.artifact_store.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [data.aws_codestarconnections_connection.github_codestar_connection.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:ListConnections"]
    resources = ["arn:aws:codestar-connections:${local.region_account}:*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [
      aws_kms_key.artifact_store_kms_key.arn
    ]
  }
}

# CodeBuild
resource "aws_iam_role" "database_pipeline_codebuild" {
  name               = "${local.pipeline_name}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.assume_codebuild_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "assume_codebuild_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "artifact_store_access_for_codebuild" {
  name   = "ArtifactStoreAccess"
  role   = aws_iam_role.database_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.access_artifact_store.json
}

resource "aws_iam_role_policy" "log_access_for_codebuild" {
  name   = "LogAccess"
  role   = aws_iam_role.database_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.log_access_for_codebuild.json
}

data "aws_iam_policy_document" "log_access_for_codebuild" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:TagLogGroup"
    ]
    resources = [
      aws_cloudwatch_log_group.database_pipeline_codebuild.arn,
      "${aws_cloudwatch_log_group.database_pipeline_codebuild.arn}:*",
      "arn:aws:logs:${local.region_account}:log-group:*"
    ]
  }
}

resource "aws_iam_role_policy" "ssm_read_access_for_codebuild" {
  name   = "SSMAccess"
  role   = aws_iam_role.database_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.ssm_access.json
}

data "aws_iam_policy_document" "ssm_access" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:${local.region_account}:parameter/codebuild/slack_*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = [
      "arn:aws:ssm:${local.region_account}:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DeleteParameter",
      "ssm:AddTagsToResource",
      "ssm:ListTagsForResource"
    ]
    resources = [
      "arn:aws:ssm:${local.region_account}:parameter/copilot/${var.application}/*/secrets/*",
      "arn:aws:ssm:${local.region_account}:parameter/copilot/applications/${var.application}",
      "arn:aws:ssm:${local.region_account}:parameter/copilot/applications/${var.application}/*"
    ]
  }
}

resource "aws_iam_role_policy" "iam_access_for_codebuild" {
  name   = "IAMAccess"
  role   = aws_iam_role.database_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.iam_access.json
}

data "aws_iam_policy_document" "iam_access" {
  statement {
    effect = "Allow"
    actions = [
      "iam:ListAccountAliases"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "database_copy_access_for_codebuild" {
  name   = "DatabaseCopy"
  role   = aws_iam_role.database_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.database_copy.json
}

data "aws_iam_policy_document" "database_copy" {
  statement {
    sid    = "AllowReadOnRDSSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:aws:secretsmanager:${local.region_account}:secret:rds*"
    ]
  }

  statement {
    sid    = "AllowRunningDumpAndLoadTask"
    effect = "Allow"
    actions = [
      "ecs:RunTask",
    ]
    resources = [
      "arn:aws:ecs:${local.region_account}:task-definition/*-load:*"
    ]
  }

  statement {
    sid    = "AllowLogTrail"
    effect = "Allow"
    actions = [
      "logs:StartLiveTail",
    ]
    resources = [
      "arn:aws:logs:${local.region_account}:log-group:/ecs/*-load"
    ]
  }

  statement {
    sid    = "AllowPassRoleToTaskExec"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*-load-exec"
    ]
  }

  statement {
    sid    = "AllowDescribeLogs"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
    ]
    resources = [
      "arn:aws:logs:${local.region_account}:log-group::log-stream:"
    ]
  }

  statement {
    sid = "AllowRedisListVersions"
    actions = [
      "elasticache:DescribeCacheEngineVersions"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    sid = "AllowOpensearchListVersions"
    actions = [
      "es:ListVersions",
      "es:ListElasticsearchVersions"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "AllowDescribeVPCsAndSubnets"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups"
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "assume_dump_account_role_access_for_codebuild" {
  name   = "AssumeDumpAccountRole"
  role   = aws_iam_role.database_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.assume_dump_account_role.json
}

data "aws_iam_policy_document" "assume_dump_account_role" {
  statement {
    sid    = "AllowAssumeDumpAccountRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      local.dump_role_arn
    ]
  }
}
