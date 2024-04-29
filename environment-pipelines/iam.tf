data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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

data "aws_iam_policy_document" "access_artifact_store" {
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
      module.artifact_store.arn,
      "${module.artifact_store.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [data.aws_codestarconnections_connection.github_codestar_connection.arn]
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
      module.artifact_store.kms_key_arn
    ]
  }
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

data "aws_iam_policy_document" "write_environment_pipeline_codebuild_logs" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.environment_pipeline_codebuild.arn,
      "${aws_cloudwatch_log_group.environment_pipeline_codebuild.arn}:*"
    ]
  }
}

data "aws_s3_bucket" "state_bucket" {
  bucket = "terraform-platform-state-${var.aws_account_name}"
}

data "aws_iam_policy_document" "state_bucket_access" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      data.aws_s3_bucket.state_bucket.arn,
      "${data.aws_s3_bucket.state_bucket.arn}/*"
    ]
  }
}

data "aws_kms_key" "state_kms_key" {
  key_id = "alias/terraform-platform-state-s3-key-${var.aws_account_name}"
}

data "aws_iam_policy_document" "state_kms_key_access" {
  statement {
    actions = [
      "kms:ListKeys",
      "kms:Decrypt"
    ]
    resources = [
      data.aws_kms_key.state_kms_key.arn
    ]
  }
}

data "aws_iam_policy_document" "state_dynamo_db_access" {
  statement {
    actions = [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/terraform-platform-lockdb-${var.aws_account_name}"
    ]
  }
}

# VPC and Subnet Read perms
data "aws_iam_policy_document" "ec2_read_access" {
	statement {
      actions = [
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeSecurityGroups"
        ]
      resources = [
        "*"
      ]
  }
}

data "aws_ssm_parameter" "central_log_group_parameter" {
  name = "/copilot/tools/central_log_groups"
}

data "aws_iam_policy_document" "ssm_read_access" {
  statement {
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      data.aws_ssm_parameter.central_log_group_parameter.arn
    ]
  }
}

# Assume DNS account role
data "aws_iam_policy_document" "dns_account_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.dns_account_id}:role/sandbox-codebuild-assume-role"
    ]
  }
}

resource "aws_iam_role" "environment_pipeline_codepipeline" {
  name               = "${var.application}-environment-pipeline-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.assume_codepipeline_role.json
  tags               = local.tags
}

resource "aws_iam_role" "environment_pipeline_codebuild" {
  name               = "${var.application}-environment-pipeline-codebuild"
  assume_role_policy = data.aws_iam_policy_document.assume_codebuild_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "artifact_store_access_for_environment_codepipeline" {
  name   = "${var.application}-artifact-store-access-for-environment-codepipeline"
  role   = aws_iam_role.environment_pipeline_codepipeline.name
  policy = data.aws_iam_policy_document.access_artifact_store.json
}

resource "aws_iam_role_policy" "artifact_store_access_for_environment_codebuild" {
  name   = "${var.application}-artifact-store-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.access_artifact_store.json
}

resource "aws_iam_role_policy" "log_access_for_environment_codebuild" {
  name   = "${var.application}-log-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.write_environment_pipeline_codebuild_logs.json
}

# Terraform State bucket access
resource "aws_iam_role_policy" "state_bucket_access_for_environment_codebuild" {
  name   = "${var.application}-state-bucket-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.state_bucket_access.json
}

resource "aws_iam_role_policy" "state_kms_key_access_for_environment_codebuild" {
  name   = "${var.application}-kms-key-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.state_kms_key_access.json
}

resource "aws_iam_role_policy" "state_dynamo_db_access_for_environment_codebuild" {
  name   = "${var.application}-dynamo-db-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.state_dynamo_db_access.json
}

# VPC and Subnets
resource "aws_iam_role_policy" "ec2_read_access" {
  name   = "${var.application}-ec2-read-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.ec2_read_access.json
}

resource "aws_iam_role_policy" "ssm_read_access" {
  name   = "${var.application}-ssm-read-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.ssm_read_access.json
}

# Assume DNS account role
resource "aws_iam_role_policy" "dns_account_assume_role" {
  name   = "${var.application}-dns-account-assume-role-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.dns_account_assume_role.json
}
