resource "aws_iam_role" "external_service_access_role" {
  # TODO: Fix role name with a resource identifier other than its ARN
  name               = "TEST-ExternalServiceAccessRole"
  assume_role_policy = data.aws_iam_policy_document.allow_assume_role.json
}

data "aws_iam_policy_document" "allow_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.config.role_arn, "arn:aws:iam::763451185160:role/service-role/test-cross-account-s3-access-role-oybqycoa"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "allow_actions" {
  statement {
    sid    = "AllowActions"
    effect = "Allow"

    actions = var.config.bucket_actions

    resources = [var.resource_arn]
  }
}

resource "aws_iam_role_policy" "allow_actions" {
  name   = "${var.application}-${var.environment}-allow-actions"
  role   = aws_iam_role.external_service_access_role.name
  policy = data.aws_iam_policy_document.allow_actions.json
}
