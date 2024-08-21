data "aws_caller_identity" "current" {}
resource "aws_s3_bucket" "this" {
  # checkov:skip=CKV_AWS_144: Cross Region Replication not Required
  # checkov:skip=CKV2_AWS_62: Requires wider discussion around log/event ingestion before implementing. To be picked up on conclusion of DBTP-974
  # checkov:skip=CKV_AWS_18:  Requires wider discussion around log/event ingestion before implementing. To be picked up on conclusion of DBTP-974
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

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// Cloudfront resources for serving static content
# Create a CloudFront Origin Access Identity (OAI)
resource "aws_cloudfront_origin_access_identity" "oai" {
  count  = var.config.serve_static ? 1 : 0
  provider = aws.domain-cdn
  comment = "OAI for S3 bucket"
}

# Attach a bucket policy to allow CloudFront to access the bucket
resource "aws_s3_bucket_policy" "cloudfront_bucket_policy" {
  count = var.config.serve_static ? 1 : 0

  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai[0].iam_arn
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution[0].arn
          }
        }
      }
    ]
  })
}

data "aws_cloudfront_cache_policy" "example" {
  name = "Managed-CachingOptimized"
}

# Create a CloudFront distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  count = var.config.serve_static ? 1 : 0
  provider = aws.domain-cdn

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.this.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai[0].cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.this.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    cache_policy_id = data.aws_cloudfront_cache_policy.example.id
  }

  viewer_certificate {
    cloudfront_default_certificate = true  # Use the default CloudFront certificate (HTTPS)
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # default_root_object = "index.html" Do we want this set?

  enabled = true

  tags = local.tags
}

# Define the content of index.html inline (only if serve_static is true)
# locals {
#   index_html_content = <<EOF
# <!DOCTYPE html>
# <html lang="en">
# <head>
#     <meta charset="UTF-8">
#     <meta name="viewport" content="width=device-width, initial-scale=1.0">
#     <title>Welcome to My Website</title>
# </head>
# <body>
#     <h1>Welcome to My Static Website!</h1>
#     <p>This is the default page served by S3 and CloudFront.</p>
# </body>
# </html>
# EOF
# }

# # Conditionally upload index.html to the S3 bucket
# resource "aws_s3_object" "index_html" {
#   count  = var.serve_static ? 1 : 0
#   bucket = aws_s3_bucket.this.bucket
#   key    = "index.html"
#   content = local.index_html_content

#   # Server-side encryption using the default S3 key
#   server_side_encryption = "AES256"

#   # Ensure this object is created only after the bucket is ready
#   depends_on = [aws_s3_bucket.this]
# }

# # Output the CloudFront distribution domain name if it was created
# output "cloudfront_domain_name" {
#   value = aws_cloudfront_distribution.s3_distribution[0].domain_name
#   description = "The domain name of the CloudFront distribution"
#   condition = var.config.serve_static
# }

