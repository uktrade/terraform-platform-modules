resource "aws_iam_role" "external_service_access_role" {
  # TODO: Fix role name with a resource identifier other than its ARN
  name               = "TEST-ExternalServiceAccessRole"
  assume_role_policy = data.aws_iam_policy_document.assume_s3_role.json
}

data "aws_iam_policy_document" "assume_s3_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.config.role_arn, "arn:aws:iam::763451185160:role/service-role/test-cross-account-s3-access-role-oybqycoa"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "permissions_s3" {
  statement {
    sid    = "S3BucketAllowActions"
    effect = "Allow"

    actions = var.config.bucket_actions

    resources = [var.resource_arn]
  }
}

resource "aws_iam_role_policy" "permissions_s3_policy" {
  name   = "${var.application}-${var.environment}-permissions-s3-policy"
  role   = aws_iam_role.external_service_access_role.name
  policy = data.aws_iam_policy_document.permissions_s3.json
}
