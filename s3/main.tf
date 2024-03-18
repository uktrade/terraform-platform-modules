data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "this" {
  bucket = var.config.bucket_name

  tags = local.tags
}

data "aws_iam_policy_document" "bucket-policy" {
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
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "bucket-policy" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket-policy.json
}

resource "aws_s3_bucket_versioning" "this-versioning" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = lookup(var.config, "versioning", false) ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "object-lock-config" {
  bucket = aws_s3_bucket.this.id

  count = var.config.retention_policy != null ? 1: 0 

  rule {
    default_retention {
      mode = var.config.retention_policy.mode
      days = lookup(var.config.retention_policy, "days", null)
      years = lookup(var.config.retention_policy, "years", null)      
    }
  }
}

data "aws_iam_policy_document" "kms-key-policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    // QUESTION: Should this be scoped down?
    actions = [
      "kms:*",
    ]

    effect = "Allow"

    // QUESTION: Should this be scoped down?
    resources = ["*"]
  }
}

resource "aws_kms_key" "kms-key" {
  description             = "KMS Key for S3 encryption"
  policy = data.aws_iam_policy_document.kms-key-policy.json
  tags = local.tags
}

resource "aws_kms_alias" "key-alias" {
  depends_on = [aws_kms_key.kms-key]
  name          = "alias/${var.application}-${var.application}S3Bucket-key"
  target_key_id = aws_kms_key.kms-key.id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption-config" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kms-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

// Upload files 
resource "aws_s3_object" "object" {
  for_each = { for item in lookup(var.config, "objects", []): item.key => item.body } 

  bucket = aws_s3_bucket.this.id
  key    = each.key
  content = each.value
} 
