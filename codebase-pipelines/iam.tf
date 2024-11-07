data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "codebase_image_build" {
  name               = "${var.application}-${var.codebase}-codebase-image-build"
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

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.codebase_image_build.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy" "codebuild_logs" {
  name   = "log-policy"
  role   = aws_iam_role.codebase_image_build.name
  policy = data.aws_iam_policy_document.codebuild_logs.json
}

data "aws_iam_policy_document" "codebuild_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:TagLogGroup"
    ]
    resources = [
      aws_cloudwatch_log_group.codebase_image_build.arn,
      "${aws_cloudwatch_log_group.codebase_image_build.arn}:*",
      "arn:aws:logs:${local.account_region}:log-group:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
    ]
    resources = [
      "arn:aws:codebuild:${local.account_region}:report-group/${aws_codebuild_project.codebase_image_build.name}-*",
      "arn:aws:codebuild:${local.account_region}:report-group/pipeline-${var.application}-*"
    ]
  }
}

resource "aws_iam_role_policy" "ecr_access" {
  name   = "ecr-policy"
  role   = aws_iam_role.codebase_image_build.name
  policy = data.aws_iam_policy_document.ecr_access.json
}

data "aws_iam_policy_document" "ecr_access" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = [
      "arn:aws:codebuild:${local.account_region}:report-group/pipeline-${var.application}-*"
    ]
  }

  statement {
    # checkov:skip=CKV_AWS_107:GetAuthorizationToken required for ci-image-builder
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr-public:GetAuthorizationToken",
      "sts:GetServiceBearerToken"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr-public:DescribeImageScanFindings",
      "ecr-public:GetLifecyclePolicyPreview",
      "ecr-public:GetDownloadUrlForLayer",
      "ecr-public:BatchGetImage",
      "ecr-public:DescribeImages",
      "ecr-public:ListTagsForResource",
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:GetLifecyclePolicy",
      "ecr-public:GetRepositoryPolicy",
      "ecr-public:PutImage",
      "ecr-public:InitiateLayerUpload",
      "ecr-public:UploadLayerPart",
      "ecr-public:CompleteLayerUpload",
      "ecr-public:BatchDeleteImage",
      "ecr-public:DescribeRepositories",
      "ecr-public:ListImages"
    ]
    resources = [
      "arn:aws:ecr-public::${data.aws_caller_identity.current.account_id}:repository/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeImageScanFindings",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:ListTagsForResource",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetLifecyclePolicy",
      "ecr:GetRepositoryPolicy",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:BatchDeleteImage",
      "ecr:DescribeRepositories",
      "ecr:ListImages"
    ]
    resources = [
      aws_ecr_repository.this.arn
    ]
  }
}

resource "aws_iam_role_policy" "codestar_connection_access" {
  name   = "codestar-connection-policy"
  role   = aws_iam_role.codebase_image_build.name
  policy = data.aws_iam_policy_document.codestar_connection_access.json
}

data "aws_iam_policy_document" "codestar_connection_access" {
  statement {
    effect = "Allow"
    actions = [
      "codestar-connections:GetConnectionToken",
      "codestar-connections:UseConnection"
    ]
    resources = [
      data.aws_codestarconnections_connection.github_codestar_connection.arn
    ]
  }
}
