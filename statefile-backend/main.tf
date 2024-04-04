terraform {
  required_version = ">= 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.38.0"
    }
  }
}

resource "aws_s3_bucket" "terraform-state" {
  bucket = "terraform-platform-state-${var.aws_account_name}"
  tags = merge(
    local.tags,
    {
      purpose = "Terraform statefile storage - DBT Platform"
    }
  )
}

resource "aws_s3_bucket_acl" "terraform-state-acl" {
  depends_on = [aws_s3_bucket_ownership_controls.terraform-state-ownership]
  bucket     = aws_s3_bucket.terraform-state.id
  acl        = "private"
}

resource "aws_s3_bucket_versioning" "terraform-state-versioning" {
  bucket = aws_s3_bucket.terraform-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "terraform-state-ownership" {
  bucket = aws_s3_bucket.terraform-state.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.terraform-state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "terraform-bucket-key" {
  description = "This key is used to encrypt bucket objects"
  tags = merge(
    local.tags,
    {
      purpose = "Terraform statefile kms key - DBT Platform"
    }
  )
}

resource "aws_kms_alias" "key-alias" {
  name          = "alias/terraform-platform-state-s3-key-${var.aws_account_name}"
  target_key_id = aws_kms_key.terraform-bucket-key.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform-state-sse" {
  bucket = aws_s3_bucket.terraform-state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform-bucket-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_dynamodb_table" "terraform-state" {
  name           = "terraform-platform-lockdb-${var.aws_account_name}"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  tags = merge(
    local.tags,
    {
      purpose = "Terraform statefile lock - DBT Platform"
    }
  )
}
