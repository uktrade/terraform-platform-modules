resource "aws_s3_bucket" "artifact_store" {
  # checkov:skip=CKV_AWS_144: Cross Region Replication not Required
  # checkov:skip=CKV2_AWS_62: Requires wider discussion around log/event ingestion before implementing. To be picked up on conclusion of DBTP-974
  # checkov:skip=CKV2_AWS_61: This bucket is only used for the pipeline artifacts, so no requirement for lifecycle configuration
  # checkov:skip=CKV_AWS_21: This bucket is only used for the pipeline artifacts, so no requirement for versioning
  # checkov:skip=CKV_AWS_18:  Requires wider discussion around log/event ingestion before implementing. To be picked up on conclusion of DBTP-974
  bucket = "${var.application}-${var.codebase}-codebase-pipeline-artifact-store"

  tags = local.tags
}

data "aws_iam_policy_document" "artifact_store_bucket_policy" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    effect = "Deny"

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = [
        "false",
      ]
    }

    resources = [
      aws_s3_bucket.artifact_store.arn,
      "${aws_s3_bucket.artifact_store.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "artifact_store_bucket_policy" {
  bucket = aws_s3_bucket.artifact_store.id
  policy = data.aws_iam_policy_document.artifact_store_bucket_policy.json
}

resource "aws_kms_key" "artifact_store_kms_key" {
  # checkov:skip=CKV_AWS_7:We are not currently rotating the keys
  description = "KMS Key for S3 encryption"
  tags        = local.tags

  policy = jsonencode({
    Id = "key-default-1"
    Statement = [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_kms_alias" "artifact_store_kms_alias" {
  depends_on    = [aws_kms_key.artifact_store_kms_key]
  name          = "alias/${var.application}-${var.codebase}-codebase-pipeline-artifact-store-key"
  target_key_id = aws_kms_key.artifact_store_kms_key.id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption-config" {
  # checkov:skip=CKV2_AWS_67:We are not currently rotating the keys
  bucket = aws_s3_bucket.artifact_store.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.artifact_store_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.artifact_store.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
