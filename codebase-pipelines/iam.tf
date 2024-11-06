data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "codebase_build" {
  name               = "${var.application}-${var.config.name}-codebase-codebuild"
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
  role       = aws_iam_role.codebase_build.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "cloudformation_access" {
  role       = aws_iam_role.codebase_build.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "${var.application}-${var.config.name}-log-policy"
  role   = aws_iam_role.codebase_build.name
  policy = data.aws_iam_policy_document.write_codebuild_logs.json
}

data "aws_iam_policy_document" "write_codebuild_logs" {
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
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${aws_cloudwatch_log_group.codebase_image_build.name}",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${aws_cloudwatch_log_group.codebase_image_build.name}:*"
    ]
  }
}
