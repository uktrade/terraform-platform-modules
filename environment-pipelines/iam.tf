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

data "aws_iam_policy_document" "state_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::terraform-platform-state-sandbox"
    ]
  }
}

#{
#"Version": "2012-10-17",
#"Statement": [
#{
#"Sid": "VisualEditor0",
#"Effect": "Allow",
#"Action": [
#"s3:*"
#],
#"Resource": "*"
#},
#{
#"Sid": "VisualEditor1",
#"Effect": "Allow",
#"Action": "s3:*",
#"Resource": "arn:aws:s3:::terraform-platform-state-sandbox"
#}
#]
#}

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

resource "aws_iam_role_policy" "state_bucket_access_for_environment_codebuild" {
  name   = "${var.application}-state-bucket-access-for-environment-codebuild"
  role   = aws_iam_role.environment_pipeline_codebuild.name
  policy = data.aws_iam_policy_document.state_bucket_access.json
}

