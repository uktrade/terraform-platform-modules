# tflint-ignore: terraform_unused_declarations
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
    status = coalesce(var.config.versioning, false) ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle-configuration" {
  count = var.config.lifecycle_rules != null ? 1 : 0

  bucket = aws_s3_bucket.this.id

  # checkov:skip=CKV_AWS_300: Ensure S3 lifecycle configuration sets period for aborting failed uploads
  dynamic "rule" {
    for_each = var.config.lifecycle_rules
    content {
      id = "rule-${index(var.config.lifecycle_rules, rule.value) + 1}"
      abort_incomplete_multipart_upload {
        days_after_initiation = 7
      }
      filter {
        prefix = rule.value.filter_prefix
      }
      expiration {
        days = rule.value.expiration_days
      }
      status = coalesce(rule.value.enabled, false) ? "Enabled" : "Disabled"
    }
  }
}

resource "aws_kms_key" "kms-key" {
  description = "KMS Key for S3 encryption"
  tags        = local.tags
}

resource "aws_kms_alias" "s3-bucket" {
  depends_on    = [aws_kms_key.kms-key]
  name          = "alias/${local.kms_alias_name}"
  target_key_id = aws_kms_key.kms-key.id
}

// require server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption-config" {
  # checkov:skip=CKV2_AWS_67:We are not currently rotating the keys
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kms-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_object_lock_configuration" "object-lock-config" {
  bucket = aws_s3_bucket.this.id

  count = var.config.retention_policy != null ? 1 : 0

  rule {
    default_retention {
      mode  = var.config.retention_policy.mode
      days  = lookup(var.config.retention_policy, "days", null)
      years = lookup(var.config.retention_policy, "years", null)
    }
  }
}

// create objects based on the config.objects key
resource "aws_s3_object" "object" {
  for_each = { for item in coalesce(var.config.objects, []) : item.key => item.body }

  bucket  = aws_s3_bucket.this.id
  key     = each.key
  content = each.value

  kms_key_id             = aws_kms_key.kms-key.arn
  server_side_encryption = "aws:kms"
}
