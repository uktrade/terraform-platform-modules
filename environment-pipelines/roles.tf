resource "aws_iam_role" "environment_pipeline_role" {
  name               = "${var.application}-environment-pipeline-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = local.tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "codepipeline_policy" {
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

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.environment_pipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

data "aws_iam_policy_document" "assume_environment_codebuild_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "environment_codebuild_role" {
  name               = "${var.application}-environment-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.assume_environment_codebuild_role.json
}


data "aws_iam_policy_document" "environment_codebuild_policy" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
#      aws_cloudwatch_log_group.codebuild_log_group.arn,
#      "${aws_cloudwatch_log_group.codebuild_log_group.arn}:*"
      "*"
    ]
  }

}

resource "aws_iam_role_policy" "environment_codebuild_role_policy" {
  role   = aws_iam_role.environment_codebuild_role.name
  policy = data.aws_iam_policy_document.environment_codebuild_policy.json
}


#data "aws_iam_policy_document" "environment_codebuild_policy" {
#  statement {
#    effect = "Allow"
#
#    actions = [
#      "logs:CreateLogGroup",
#      "logs:CreateLogStream",
#      "logs:PutLogEvents",
#    ]
#
#    resources = ["*"]
#  }
#
#  statement {
#    effect = "Allow"
#
#    actions = [
#      "ec2:CreateNetworkInterface",
#      "ec2:DescribeDhcpOptions",
#      "ec2:DescribeNetworkInterfaces",
#      "ec2:DeleteNetworkInterface",
#      "ec2:DescribeSubnets",
#      "ec2:DescribeSecurityGroups",
#      "ec2:DescribeVpcs",
#    ]
#
#    resources = ["*"]
#  }
#
#  statement {
#    effect    = "Allow"
#    actions   = ["ec2:CreateNetworkInterfacePermission"]
#    resources = ["arn:aws:ec2:us-east-1:123456789012:network-interface/*"]
#
#    condition {
#      test     = "StringEquals"
#      variable = "ec2:Subnet"
#
#      values = [
#        aws_subnet.example1.arn,
#        aws_subnet.example2.arn,
#      ]
#    }
#
#    condition {
#      test     = "StringEquals"
#      variable = "ec2:AuthorizedService"
#      values   = ["codebuild.amazonaws.com"]
#    }
#  }
#
#  statement {
#    effect  = "Allow"
#    actions = ["s3:*"]
#    resources = [
#      aws_s3_bucket.example.arn,
#      "${aws_s3_bucket.example.arn}/*",
#    ]
#  }
#}
#
#resource "aws_iam_role_policy" "environment_codebuild_role_policy" {
#  role   = aws_iam_role.environment_codebuild_role.name
#  policy = data.aws_iam_policy_document.environment_codebuild_policy.json
#}
