data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "codebase_pipeline_deploy_role" {
  name               = "${var.args.application}-${var.environment}-codebase-pipeline-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.codebase_deploy_pipeline_assume_role_policy.json
  tags               = local.tags
}

data "aws_iam_policy_document" "codebase_deploy_pipeline_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.args.pipeline_account_id}:root"]
    }
    condition {
      test = "StringLike"
      values = [
        "arn:aws:iam::${var.args.pipeline_account_id}:role/${var.args.application}-*-codebase-pipeline",
        "arn:aws:iam::${var.args.pipeline_account_id}:role/${var.args.application}-*-codebase-pipeline-deploy-manifests"
      ]
      variable = "aws:PrincipalArn"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "ecr_access_for_codebase_pipeline" {
  name   = "${var.args.application}-ecr-access-for-codebase-pipeline"
  role   = aws_iam_role.codebase_pipeline_deploy_role.name
  policy = data.aws_iam_policy_document.ecr_access_for_codebase_pipeline.json
}

data "aws_iam_policy_document" "ecr_access_for_codebase_pipeline" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeImages"
    ]
    resources = [
      "arn:aws:ecr:${data.aws_region.current.name}:${var.args.pipeline_account_id}:repository/${var.args.application}/*"
    ]
  }
}

resource "aws_iam_role_policy" "artifact_store_access_for_codebase_pipeline" {
  name   = "${var.args.application}-artifact-store-access-for-codebase-pipeline"
  role   = aws_iam_role.codebase_pipeline_deploy_role.name
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
      "arn:aws:s3:::${var.args.application}-*-codebase-pipeline-artifact-store/*",
      "arn:aws:s3:::${var.args.application}-*-codebase-pipeline-artifact-store"
    ]
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
      "arn:aws:kms:${data.aws_region.current.name}:${var.args.pipeline_account_id}:key/*"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_deploy_access_for_codebase_pipeline" {
  name   = "${var.args.application}-ecs-deploy-access-for-codebase-pipeline"
  role   = aws_iam_role.codebase_pipeline_deploy_role.name
  policy = data.aws_iam_policy_document.ecs_deploy_access_for_codebase_pipeline.json
}

data "aws_iam_policy_document" "ecs_deploy_access_for_codebase_pipeline" {
  statement {
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:TagResource",
      "ecs:ListServices"
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.args.application}-${var.environment}",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.args.application}-${var.environment}/*"
    ]
  }

  statement {
    actions = [
      "ecs:DescribeTasks",
      "ecs:TagResource"
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.args.application}-${var.environment}",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/${var.args.application}-${var.environment}/*"
    ]
  }

  statement {
    actions = [
      "ecs:RunTask",
      "ecs:TagResource"
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/${var.args.application}-${var.environment}-*:*"
    ]
  }

  statement {
    actions = [
      "ecs:ListTasks"
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:container-instance/${var.args.application}-${var.environment}/*"
    ]
  }

  statement {
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      values   = ["ecs-tasks.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }
}
