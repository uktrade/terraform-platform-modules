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
      type = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.codebase_image_build.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "cloudformation_access" {
  role       = aws_iam_role.codebase_image_build.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"
}

resource "aws_iam_role_policy" "codebuild_logs" {
  name   = "${aws_iam_role.codebase_image_build.name}-log-policy"
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
      "arn:aws:logs:${local.account_region}:log-group:/aws/codebuild/${aws_cloudwatch_log_group.codebase_image_build.name}",
      "arn:aws:logs:${local.account_region}:log-group:/aws/codebuild/${aws_cloudwatch_log_group.codebase_image_build.name}:*"
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
  name   = "${aws_iam_role.codebase_image_build.name}-ecr-policy"
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
    effect = "Allow"
    actions = [
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
      "ecr-public:*"
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
      "ecr:BatchDeleteImage"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "codestar_connection_access" {
  name   = "${aws_iam_role.codebase_image_build.name}-codestar-connection-policy"
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
