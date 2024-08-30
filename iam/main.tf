resource "aws_iam_role" "external_service_access_role" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.allow_assume_role.json
}

data "aws_iam_policy_document" "allow_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.config.importing_role_arn]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "s3_external_import" {
  statement {
    sid    = "ReadOnSourceBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging"
    ]

    resources = [
      var.config.source_bucket_arn,
    "${var.config.source_bucket_arn}/*"]
  }

  statement {
    sid    = "WriteOnDestinationBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging"
    ]

    resources = [
      var.bucket_arn,
    "${var.bucket_arn}/*"]
  }

  statement {
    sid    = "AllowActions"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*", # Needed for object decryption
      "kms:DescribeKey"       # Allow describing the key
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.external_service_access_role.arn]
    }

    resources = ["*"] # Required to be passed in in the config
  }
}

resource "aws_iam_role_policy" "s3_external_import_policy" {
  name   = "${var.application}-${var.environment}-allow-s3-external-import-actions"
  role   = aws_iam_role.external_service_access_role.name
  policy = data.aws_iam_policy_document.s3_external_import.json
}